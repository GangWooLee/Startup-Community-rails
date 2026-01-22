require "test_helper"

class DeviceTest < ActiveSupport::TestCase
  fixtures :users, :devices

  setup do
    @user = users(:one)
    @device = devices(:ios_device)
  end

  # ==========================================================================
  # Validations
  # ==========================================================================

  test "should be valid with valid attributes" do
    assert @device.valid?
  end

  test "should require platform" do
    @device.platform = nil
    assert_not @device.valid?
    assert_includes @device.errors[:platform], "can't be blank"
  end

  test "should only allow ios or android platform" do
    @device.platform = "ios"
    assert @device.valid?

    @device.platform = "android"
    assert @device.valid?

    @device.platform = "windows"
    assert_not @device.valid?
    assert_includes @device.errors[:platform], "is not included in the list"
  end

  test "should require token" do
    @device.token = nil
    assert_not @device.valid?
    assert_includes @device.errors[:token], "can't be blank"
  end

  test "should require unique token" do
    duplicate = Device.new(
      user: users(:two),
      platform: "android",
      token: @device.token
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:token], "has already been taken"
  end

  # ==========================================================================
  # Associations
  # ==========================================================================

  test "should belong to user" do
    assert_respond_to @device, :user
    assert_equal @user, @device.user
  end

  # ==========================================================================
  # Scopes
  # ==========================================================================

  test "enabled scope returns only enabled devices" do
    enabled_devices = Device.enabled

    assert enabled_devices.all?(&:enabled)
    assert_includes enabled_devices, devices(:ios_device)
    assert_not_includes enabled_devices, devices(:android_device_disabled)
  end

  test "ios scope returns only ios devices" do
    ios_devices = Device.ios

    assert ios_devices.all? { |d| d.platform == "ios" }
    assert_includes ios_devices, devices(:ios_device)
    assert_not_includes ios_devices, devices(:android_device)
  end

  test "android scope returns only android devices" do
    android_devices = Device.android

    assert android_devices.all? { |d| d.platform == "android" }
    assert_includes android_devices, devices(:android_device)
    assert_not_includes android_devices, devices(:ios_device)
  end

  test "recently_used scope returns devices used within 30 days" do
    recent_devices = Device.recently_used

    assert recent_devices.all? { |d| d.last_used_at > 30.days.ago }
    assert_includes recent_devices, devices(:ios_device)
    assert_not_includes recent_devices, devices(:old_device)
  end

  # ==========================================================================
  # Class Methods
  # ==========================================================================

  test "register creates new device with valid params" do
    new_token = "new_token_#{SecureRandom.hex(8)}"

    device = Device.register(
      user: @user,
      platform: "android",
      token: new_token,
      device_name: "Galaxy S24",
      app_version: "1.0.0"
    )

    assert device.persisted?
    assert_equal @user, device.user
    assert_equal "android", device.platform
    assert_equal new_token, device.token
    assert_equal "Galaxy S24", device.device_name
    assert_equal "1.0.0", device.app_version
    assert device.enabled
    assert_in_delta Time.current, device.last_used_at, 1.second
  end

  test "register updates existing device with same token" do
    existing_token = @device.token
    original_id = @device.id

    device = Device.register(
      user: users(:two),
      platform: "android",
      token: existing_token,
      device_name: "New Device",
      app_version: "2.0.0"
    )

    assert_equal original_id, device.id
    assert_equal users(:two), device.user
    assert_equal "android", device.platform
    assert_equal "New Device", device.device_name
    assert_equal "2.0.0", device.app_version
  end

  test "register re-enables disabled device" do
    disabled_device = devices(:android_device_disabled)
    assert_not disabled_device.enabled

    device = Device.register(
      user: disabled_device.user,
      platform: disabled_device.platform,
      token: disabled_device.token
    )

    assert device.enabled
  end

  # ==========================================================================
  # Instance Methods
  # ==========================================================================

  test "ios? returns true for ios platform" do
    assert devices(:ios_device).ios?
    assert_not devices(:android_device).ios?
  end

  test "android? returns true for android platform" do
    assert devices(:android_device).android?
    assert_not devices(:ios_device).android?
  end

  test "touch_usage! updates last_used_at" do
    original_time = @device.last_used_at

    freeze_time do
      @device.touch_usage!
      @device.reload

      assert_equal Time.current, @device.last_used_at
      assert_not_equal original_time, @device.last_used_at
    end
  end

  test "disable! sets enabled to false" do
    assert @device.enabled

    @device.disable!
    @device.reload

    assert_not @device.enabled
  end

  # ==========================================================================
  # User Association
  # ==========================================================================

  test "user can have multiple devices" do
    user_devices = @user.devices

    assert_operator user_devices.count, :>=, 1
    assert user_devices.all? { |d| d.user_id == @user.id }
  end

  test "deleting user deletes associated devices" do
    user = User.create!(
      email: "temp_device_test@example.com",
      name: "Temp User",
      password: "test1234"
    )

    device = Device.create!(
      user: user,
      platform: "ios",
      token: "temp_token_#{SecureRandom.hex(8)}"
    )

    device_id = device.id

    user.destroy

    assert_nil Device.find_by(id: device_id)
  end
end
