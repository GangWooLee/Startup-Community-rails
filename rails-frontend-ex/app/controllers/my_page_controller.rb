class MyPageController < ApplicationController
  def show
    # TODO: Fetch current user data
    @user = {
      name: "김창업",
      email: "kim@example.com",
      avatar: "/diverse-user-avatars.png",
      role: "CEO",
      company: "스타트업 A"
    }
  end

  def edit
    # TODO: Load user data for editing
    @user = {
      name: "김창업",
      email: "kim@example.com",
      bio: "Zero to One을 만들어가는 창업자입니다.",
      location: "서울, 한국",
      website: "https://startup-a.com"
    }
  end

  def update
    # TODO: Implement user update logic
    redirect_to my_page_path, notice: "프로필이 업데이트되었습니다."
  end
end
