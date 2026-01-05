# frozen_string_literal: true

# 기술 스택 아이콘 헬퍼
# Devicon CDN을 활용하여 스킬 이름에 맞는 아이콘을 렌더링합니다.
module SkillHelper
  # Devicon 클래스 매핑
  # 참고: https://devicon.dev/
  SKILL_ICONS = {
    # Languages
    "Ruby" => "devicon-ruby-plain colored",
    "ruby" => "devicon-ruby-plain colored",
    "Python" => "devicon-python-plain colored",
    "python" => "devicon-python-plain colored",
    "JavaScript" => "devicon-javascript-plain colored",
    "javascript" => "devicon-javascript-plain colored",
    "JS" => "devicon-javascript-plain colored",
    "TypeScript" => "devicon-typescript-plain colored",
    "typescript" => "devicon-typescript-plain colored",
    "TS" => "devicon-typescript-plain colored",
    "Java" => "devicon-java-plain colored",
    "java" => "devicon-java-plain colored",
    "Go" => "devicon-go-plain colored",
    "go" => "devicon-go-plain colored",
    "Golang" => "devicon-go-plain colored",
    "Rust" => "devicon-rust-plain",
    "rust" => "devicon-rust-plain",
    "Swift" => "devicon-swift-plain colored",
    "swift" => "devicon-swift-plain colored",
    "Kotlin" => "devicon-kotlin-plain colored",
    "kotlin" => "devicon-kotlin-plain colored",
    "C++" => "devicon-cplusplus-plain colored",
    "c++" => "devicon-cplusplus-plain colored",
    "C#" => "devicon-csharp-plain colored",
    "c#" => "devicon-csharp-plain colored",
    "PHP" => "devicon-php-plain colored",
    "php" => "devicon-php-plain colored",

    # Frameworks - Backend
    "Rails" => "devicon-rails-plain colored",
    "rails" => "devicon-rails-plain colored",
    "Ruby on Rails" => "devicon-rails-plain colored",
    "Django" => "devicon-django-plain colored",
    "django" => "devicon-django-plain colored",
    "Flask" => "devicon-flask-original colored",
    "flask" => "devicon-flask-original colored",
    "FastAPI" => "devicon-fastapi-plain colored",
    "fastapi" => "devicon-fastapi-plain colored",
    "Spring" => "devicon-spring-plain colored",
    "spring" => "devicon-spring-plain colored",
    "Spring Boot" => "devicon-spring-plain colored",
    "Node.js" => "devicon-nodejs-plain colored",
    "nodejs" => "devicon-nodejs-plain colored",
    "Express" => "devicon-express-original",
    "express" => "devicon-express-original",
    "NestJS" => "devicon-nestjs-plain colored",
    "nestjs" => "devicon-nestjs-plain colored",

    # Frameworks - Frontend
    "React" => "devicon-react-original colored",
    "react" => "devicon-react-original colored",
    "Vue" => "devicon-vuejs-plain colored",
    "vue" => "devicon-vuejs-plain colored",
    "Vue.js" => "devicon-vuejs-plain colored",
    "Angular" => "devicon-angularjs-plain colored",
    "angular" => "devicon-angularjs-plain colored",
    "Svelte" => "devicon-svelte-plain colored",
    "svelte" => "devicon-svelte-plain colored",
    "Next.js" => "devicon-nextjs-original",
    "nextjs" => "devicon-nextjs-original",
    "Nuxt" => "devicon-nuxtjs-plain colored",
    "nuxt" => "devicon-nuxtjs-plain colored",

    # Design Tools
    "Figma" => "devicon-figma-plain colored",
    "figma" => "devicon-figma-plain colored",
    "Sketch" => "devicon-sketch-line colored",
    "sketch" => "devicon-sketch-line colored",
    "XD" => "devicon-xd-plain colored",
    "Adobe XD" => "devicon-xd-plain colored",
    "Photoshop" => "devicon-photoshop-plain colored",
    "photoshop" => "devicon-photoshop-plain colored",
    "Illustrator" => "devicon-illustrator-plain colored",
    "illustrator" => "devicon-illustrator-plain colored",

    # Databases
    "PostgreSQL" => "devicon-postgresql-plain colored",
    "postgresql" => "devicon-postgresql-plain colored",
    "Postgres" => "devicon-postgresql-plain colored",
    "MySQL" => "devicon-mysql-plain colored",
    "mysql" => "devicon-mysql-plain colored",
    "MongoDB" => "devicon-mongodb-plain colored",
    "mongodb" => "devicon-mongodb-plain colored",
    "Redis" => "devicon-redis-plain colored",
    "redis" => "devicon-redis-plain colored",
    "SQLite" => "devicon-sqlite-plain colored",
    "sqlite" => "devicon-sqlite-plain colored",
    "Firebase" => "devicon-firebase-plain colored",
    "firebase" => "devicon-firebase-plain colored",

    # DevOps & Cloud
    "Docker" => "devicon-docker-plain colored",
    "docker" => "devicon-docker-plain colored",
    "Kubernetes" => "devicon-kubernetes-plain colored",
    "kubernetes" => "devicon-kubernetes-plain colored",
    "K8s" => "devicon-kubernetes-plain colored",
    "AWS" => "devicon-amazonwebservices-original colored",
    "aws" => "devicon-amazonwebservices-original colored",
    "GCP" => "devicon-googlecloud-plain colored",
    "gcp" => "devicon-googlecloud-plain colored",
    "Google Cloud" => "devicon-googlecloud-plain colored",
    "Azure" => "devicon-azure-plain colored",
    "azure" => "devicon-azure-plain colored",
    "Linux" => "devicon-linux-plain",
    "linux" => "devicon-linux-plain",
    "Nginx" => "devicon-nginx-original colored",
    "nginx" => "devicon-nginx-original colored",

    # Tools
    "Git" => "devicon-git-plain colored",
    "git" => "devicon-git-plain colored",
    "GitHub" => "devicon-github-original",
    "github" => "devicon-github-original",
    "GitLab" => "devicon-gitlab-plain colored",
    "gitlab" => "devicon-gitlab-plain colored",
    "VS Code" => "devicon-vscode-plain colored",
    "vscode" => "devicon-vscode-plain colored",
    "Vim" => "devicon-vim-plain colored",
    "vim" => "devicon-vim-plain colored",

    # CSS
    "Tailwind" => "devicon-tailwindcss-plain colored",
    "tailwind" => "devicon-tailwindcss-plain colored",
    "TailwindCSS" => "devicon-tailwindcss-plain colored",
    "CSS" => "devicon-css3-plain colored",
    "css" => "devicon-css3-plain colored",
    "Sass" => "devicon-sass-original colored",
    "sass" => "devicon-sass-original colored",
    "SCSS" => "devicon-sass-original colored",
    "Bootstrap" => "devicon-bootstrap-plain colored",
    "bootstrap" => "devicon-bootstrap-plain colored",

    # Mobile
    "Flutter" => "devicon-flutter-plain colored",
    "flutter" => "devicon-flutter-plain colored",
    "React Native" => "devicon-react-original colored",
    "iOS" => "devicon-apple-original",
    "Android" => "devicon-android-plain colored",
    "android" => "devicon-android-plain colored",

    # Testing
    "Jest" => "devicon-jest-plain colored",
    "jest" => "devicon-jest-plain colored",
    "RSpec" => "devicon-rspec-original colored",
    "rspec" => "devicon-rspec-original colored",
    "Selenium" => "devicon-selenium-original",
    "selenium" => "devicon-selenium-original"
  }.freeze

  # 스킬 이름에 맞는 아이콘 색상 (폴백용)
  SKILL_COLORS = {
    # 레드 계열
    "Ruby" => "bg-red-50 text-red-600",
    "Rails" => "bg-red-50 text-red-600",

    # 블루 계열
    "React" => "bg-sky-50 text-sky-600",
    "TypeScript" => "bg-blue-50 text-blue-600",
    "Python" => "bg-blue-50 text-blue-700",
    "Docker" => "bg-blue-50 text-blue-500",
    "Flutter" => "bg-sky-50 text-sky-500",

    # 그린 계열
    "Vue" => "bg-emerald-50 text-emerald-600",
    "Node.js" => "bg-green-50 text-green-600",
    "Django" => "bg-green-50 text-green-700",
    "MongoDB" => "bg-green-50 text-green-600",

    # 옐로우/오렌지 계열
    "JavaScript" => "bg-yellow-50 text-yellow-600",
    "Firebase" => "bg-amber-50 text-amber-600",
    "AWS" => "bg-orange-50 text-orange-600",

    # 퍼플 계열
    "Figma" => "bg-purple-50 text-purple-600",
    "Kotlin" => "bg-purple-50 text-purple-500",
    "PHP" => "bg-indigo-50 text-indigo-600",

    # 핑크 계열
    "Sass" => "bg-pink-50 text-pink-500",

    # 시안 계열
    "Tailwind" => "bg-cyan-50 text-cyan-600",
    "Go" => "bg-cyan-50 text-cyan-600",

    # 기본 (회색)
    "default" => "bg-stone-50 text-stone-500"
  }.freeze

  # 스킬 아이콘 렌더링
  # @param skill [String] 스킬 이름
  # @param size [String] 아이콘 크기 (sm, md, lg)
  # @return [String] 아이콘 HTML
  def skill_icon(skill, size: "md")
    skill_name = skill.to_s.strip
    icon_class = SKILL_ICONS[skill_name]

    size_class = case size
                 when "sm" then "text-base"
                 when "lg" then "text-2xl"
                 else "text-xl"
    end

    if icon_class.present?
      # Devicon 아이콘 사용
      tag.i(class: "#{icon_class} #{size_class}")
    else
      # 폴백: 첫 글자 배지
      fallback_skill_badge(skill_name, size)
    end
  end

  # 스킬에 맞는 배경색 클래스 반환
  # @param skill [String] 스킬 이름
  # @return [String] Tailwind 클래스
  def skill_color_class(skill)
    skill_name = skill.to_s.strip
    SKILL_COLORS[skill_name] || SKILL_COLORS["default"]
  end

  # 스킬이 Devicon을 가지고 있는지 확인
  # @param skill [String] 스킬 이름
  # @return [Boolean]
  def skill_has_icon?(skill)
    SKILL_ICONS.key?(skill.to_s.strip)
  end

  private

  # 폴백 배지 (첫 글자)
  def fallback_skill_badge(skill_name, size)
    badge_size = case size
                 when "sm" then "w-5 h-5 text-[10px]"
                 when "lg" then "w-8 h-8 text-sm"
                 else "w-6 h-6 text-xs"
    end

    color_class = skill_color_class(skill_name)

    tag.span(
      skill_name[0]&.upcase || "?",
      class: "#{badge_size} rounded-md #{color_class} flex items-center justify-center font-bold"
    )
  end
end
