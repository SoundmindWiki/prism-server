module SessionSerializer
  module_function

  def call(session, current: false)
    {
      id: session.id,
      current: current,
      device: describe(session.user_agent),
      ip_address: session.ip_address,
      last_active_at: session.last_active_at,
      expires_at: session.expires_at,
      created_at: session.created_at
    }
  end

  # user agent 문자열을 사람이 알아볼 한 줄로 줄인다.
  # 정확한 분석이 목적이 아니라, "이게 내 기기 맞나" 를 알아보게 하는 게 목적이다.
  def describe(agent)
    return "알 수 없는 기기" if agent.blank?

    browser =
      case agent
      when /Edg\//        then "Edge"
      when /OPR\/|Opera/  then "Opera"
      when /Chrome\//     then "Chrome"
      when /Firefox\//    then "Firefox"
      when /Safari\//     then "Safari"
      else "기타 브라우저"
      end

    platform =
      case agent
      when /iPhone/            then "iPhone"
      when /iPad/              then "iPad"
      when /Android/           then "Android"
      when /Macintosh|Mac OS/  then "Mac"
      when /Windows/           then "Windows"
      when /Linux/             then "Linux"
      else nil
      end

    [ browser, platform ].compact.join(" · ")
  end
end
