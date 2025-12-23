module NotificationsHelper
  # 알림 액션별 텍스트
  def notification_action_text(action)
    case action
    when "comment"
      "님이 회원님의 글에 댓글을 남겼습니다."
    when "like"
      "님이 회원님의 글을 좋아합니다."
    when "reply"
      "님이 회원님의 댓글에 답글을 남겼습니다."
    when "follow"
      "님이 회원님을 팔로우합니다."
    when "apply"
      "님이 회원님의 공고에 지원했습니다."
    else
      "님이 새로운 활동을 했습니다."
    end
  end

  # 알림 액션별 아이콘 배경색
  def notification_icon_bg(action)
    case action
    when "comment", "reply"
      "bg-blue-500"
    when "like"
      "bg-red-500"
    when "follow"
      "bg-purple-500"
    when "apply"
      "bg-green-500"
    else
      "bg-primary"
    end
  end

  # 알림 액션별 아이콘 SVG
  def notification_icon(action)
    case action
    when "comment", "reply"
      content_tag(:svg, class: "w-3 h-3 text-white", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        content_tag(:path, nil, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2",
          d: "M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z")
      end
    when "like"
      content_tag(:svg, class: "w-3 h-3 text-white", fill: "currentColor", viewBox: "0 0 24 24") do
        content_tag(:path, nil, d: "M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z")
      end
    when "follow"
      content_tag(:svg, class: "w-3 h-3 text-white", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        content_tag(:path, nil, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2",
          d: "M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z")
      end
    when "apply"
      content_tag(:svg, class: "w-3 h-3 text-white", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        content_tag(:path, nil, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2",
          d: "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z")
      end
    else
      content_tag(:svg, class: "w-3 h-3 text-white", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        content_tag(:path, nil, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2",
          d: "M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9")
      end
    end
  end

  # 알림 대상 내용 미리보기
  def notification_preview(notification)
    case notification.notifiable_type
    when "Comment"
      notification.notifiable&.content&.truncate(50)
    when "Post"
      notification.notifiable&.title&.truncate(50)
    when "Like"
      like = notification.notifiable
      if like&.likeable_type == "Post"
        like.likeable&.title&.truncate(50)
      elsif like&.likeable_type == "Comment"
        like.likeable&.content&.truncate(50)
      end
    else
      nil
    end
  end
end
