# 처음 켰을 때 빈 화면을 보지 않도록 채워 두는 기본 데이터.
# 카테고리는 실제 팀 구성을 그대로 따른다. 팀마다 자기 일에 쓰는 프롬프트가 다르기 때문이다.
#
# 분류 체계를 바꾼 뒤에는 `bin/rails db:reset` 으로 통째로 다시 만드는 편이 깔끔하다.
# `db:seed` 만 돌리면 예전 카테고리와 문서가 그대로 남는다.

puts "시드 데이터를 넣습니다..."

PRODUCTION = Rails.env.production?

# 관리자 계정 하나는 어느 환경에나 있어야 한다. 이게 없으면 백오피스에 들어갈 수 없다.
ADMIN_EMAIL = ENV.fetch("SEED_ADMIN_EMAIL", "admin@example.com")

# 운영 비밀번호는 넘겨받거나, 없으면 만들어서 한 번만 보여 준다.
# 개발용 기본값을 운영에 끌고 가지 않기 위해서다.
ADMIN_PASSWORD = ENV["SEED_ADMIN_PASSWORD"].presence ||
                 (PRODUCTION ? SecureRandom.alphanumeric(16) : "1234")

# 예시 구성원들이 쓰는 비밀번호. 개발에서만 만들어진다.
DEFAULT_PASSWORD = ENV.fetch("SEED_PASSWORD", "wiki1234!")

CATEGORIES = [
  {
    slug: "wx",
    name: "WX",
    color: "sky",
    position: 1,
    description: "웹 서비스를 만드는 팀. 프론트엔드 구현, 접근성, 웹 성능"
  },
  {
    slug: "ax",
    name: "AX",
    color: "violet",
    position: 2,
    description: "AI 기능을 만드는 팀. 프롬프트 설계, 응답 품질 평가, 검색 증강"
  },
  {
    slug: "mx",
    name: "MX",
    color: "emerald",
    position: 3,
    description: "모바일 앱을 만드는 팀. 앱 구현, 크래시 분석, 스토어 배포"
  },
  {
    slug: "ux",
    name: "UX",
    color: "fuchsia",
    position: 4,
    description: "사용자 경험을 설계하는 팀. 리서치, 화면 설계, 사용성 점검"
  },
  {
    slug: "qc",
    name: "QC",
    color: "orange",
    position: 5,
    description: "품질을 확인하는 팀. 테스트 설계, 결함 보고, 릴리스 검증"
  },
  {
    slug: "ms",
    name: "MS",
    color: "amber",
    position: 6,
    description: "고객사 서비스를 맡아 운영하는 팀. 장애 대응, 고객 문의, 운영 보고"
  },
  {
    slug: "pmo",
    name: "PMO",
    color: "rose",
    position: 7,
    description: "프로젝트를 굴리는 팀. 일정과 범위, 리스크, 이해관계자 보고"
  },
  {
    slug: "biz-support",
    name: "경영지원팀",
    color: "teal",
    position: 8,
    description: "사람과 살림을 맡는 팀. 채용, 사내 공지, 규정 안내, 비용 처리"
  },
  {
    slug: "ceo-office",
    name: "대표이사실",
    color: "indigo",
    position: 9,
    description: "경영 판단을 돕는 자리. 경영 보고 요약, 대외 커뮤니케이션, 이사회 준비"
  },
  {
    slug: "rnd",
    name: "기업부설연구소",
    color: "cyan",
    position: 10,
    description: "먼저 알아보는 팀. 기술 조사, 실험 설계, 연구개발 과제 문서"
  }
].freeze

# 도메인(산업 분야). 운영에는 맨 위 7개만 만들고, 하위 분야는 백오피스에서 필요한 만큼 붙인다.
# 개발에서는 트리가 어떻게 보이는지 확인할 수 있게 하위 분야를 몇 개 더 둔다.
DOMAINS = [
  { slug: "manufacturing", name: "제조", description: "공장·생산·품질 관리",
    children: [ { slug: "automotive", name: "자동차" }, { slug: "semiconductor", name: "반도체·전자" } ] },
  { slug: "finance", name: "금융/보험", description: "은행·보험·증권",
    children: [ { slug: "banking", name: "은행" }, { slug: "insurance", name: "보험" }, { slug: "securities", name: "증권" } ] },
  { slug: "public", name: "공공", description: "중앙부처·지자체·공공기관",
    children: [ { slug: "central-gov", name: "중앙부처" }, { slug: "local-gov", name: "지자체" } ] },
  { slug: "healthcare", name: "헬스케어", description: "병원·제약·바이오",
    children: [ { slug: "hospital", name: "병원" }, { slug: "pharma", name: "제약·바이오" } ] },
  { slug: "defense", name: "국방", description: "군·방산" },
  { slug: "shipbuilding", name: "조선", description: "조선·해양" },
  { slug: "education", name: "교육", description: "학교·에듀테크" }
].freeze

ADMIN = { email: ADMIN_EMAIL, name: "오태훈", department: "WX", job_rank: "매니저", job_title: "테크리드", role: "admin", password: ADMIN_PASSWORD }.freeze

# 운영에는 예시 구성원을 만들지 않는다. 실제 팀원은 백오피스에서 추가한다.
EXAMPLE_MEMBERS = [
  { email: "jiwon.kim@soundmind.example", name: "김지원", department: "AX", job_rank: "팀장", job_title: "AI 엔지니어", role: "admin" },
  { email: "haneul.lee@soundmind.example", name: "이하늘", department: "MX", job_rank: "매니저", job_title: "모바일 엔지니어" },
  { email: "dae.jung@soundmind.example", name: "정다은", department: "MS", job_rank: "팀장", job_title: "서비스 운영 매니저" },
  { email: "minjun.choi@soundmind.example", name: "최민준", department: "PMO", job_rank: "매니저", job_title: "프로젝트 매니저" },
  { email: "seoyeon.park@soundmind.example", name: "박서연", department: "경영지원팀", job_rank: "매니저", job_title: "HR 매니저" },
  { email: "garam.yoon@soundmind.example", name: "윤가람", department: "대표이사실", job_rank: "매니저", job_title: "경영기획" },
  { email: "jihoo.han@soundmind.example", name: "한지후", department: "기업부설연구소", job_rank: "매니저", job_title: "선임연구원" },
  { email: "retired@soundmind.example", name: "퇴사자 예시", department: "MX", job_rank: "매니저", job_title: "프로덕트 디자이너", active: false }
].freeze

MEMBERS = (PRODUCTION ? [ ADMIN ] : [ ADMIN, *EXAMPLE_MEMBERS ]).freeze

# 팀마다 그 팀 사람이 문서를 소유한다. 운영에는 그 사람들이 없으므로 관리자가 전부 맡는다.
TEAM_OWNER = {
  "wx" => ADMIN_EMAIL,
  "ax" => "jiwon.kim@soundmind.example",
  "mx" => "haneul.lee@soundmind.example",
  "ms" => "dae.jung@soundmind.example",
  "pmo" => "minjun.choi@soundmind.example",
  "biz-support" => "seoyeon.park@soundmind.example",
  "ceo-office" => "garam.yoon@soundmind.example",
  "rnd" => "jihoo.han@soundmind.example"
}.freeze

categories = CATEGORIES.to_h do |attributes|
  category = Category.find_or_initialize_by(slug: attributes[:slug])
  category.update!(attributes.except(:slug))
  [ attributes[:slug], category ]
end

domains = {}
DOMAINS.each_with_index do |attributes, index|
  root = Domain.find_or_initialize_by(slug: attributes[:slug])
  root.update!(name: attributes[:name], description: attributes[:description], parent: nil, position: index + 1)
  domains[root.slug] = root
  next if PRODUCTION

  Array(attributes[:children]).each_with_index do |child, child_index|
    node = Domain.find_or_initialize_by(slug: child[:slug])
    node.update!(name: child[:name], parent: root, position: child_index + 1)
    domains[node.slug] = node
  end
end

members = MEMBERS.to_h do |attributes|
  user = User.find_or_initialize_by(email: attributes[:email])
  user.assign_attributes(attributes.except(:email, :password))
  # 이미 있는 계정의 비밀번호는 건드리지 않는다. 시드를 다시 돌린다고 로그인 정보가 바뀌면 곤란하다.
  user.password = attributes[:password] || DEFAULT_PASSWORD if user.password_digest.blank?
  user.save!
  [ attributes[:email], user ]
end

admin = members.fetch(ADMIN_EMAIL)

PROMPTS = [
  # ---------------- WX ----------------
  {
    title: "웹 접근성 점검",
    category: "wx",
    model_hint: "Claude Opus 5",
    tags: %w[접근성 프론트엔드 품질],
    summary: "마크업을 붙여 넣으면 스크린리더와 키보드 관점에서 막히는 곳을 짚어 줍니다.",
    usage_notes: "자동 검사 도구가 못 잡는 것(포커스 순서, 레이블이 맥락과 안 맞는 경우) 위주로 나옵니다. axe 결과와 같이 쓰면 좋습니다.",
    body: <<~PROMPT
      아래 마크업의 웹 접근성을 점검해 주세요.

      ## 화면 설명
      {{이_화면이_하는_일}}

      ## 마크업
      ```html
      {{마크업}}
      ```

      ## 점검 기준
      앞에 있을수록 중요합니다.
      1. **키보드만으로 쓸 수 있는가** — 모든 동작에 도달 가능한지, 포커스 순서가 화면 순서와 맞는지, 포커스가 갇히지 않는지
      2. **스크린리더가 읽었을 때 뜻이 통하는가** — 역할(role), 이름(name), 상태(state)
      3. **의미 있는 마크업인가** — div 로 버튼을 만들지 않았는지, 제목 단계가 건너뛰지 않는지
      4. **색에만 기대지 않는가** — 오류·상태를 색 말고 무엇으로도 알리는지
      5. **동적 변화를 알리는가** — 로딩, 오류, 토스트

      ## 출력 형식
      - **[심각도: 높음/보통/낮음] 해당 요소** — 무엇이 문제인지 한 줄
        - 누가 어떻게 막히는지: (구체적인 상황으로)
        - 고친 마크업: (코드로)

      WCAG 조항 번호를 아는 경우에만 덧붙이고, 모르면 쓰지 마세요.
      문제가 없으면 "이상 없음" 한 줄로 끝내세요.
    PROMPT
  },
  {
    title: "컴포넌트 정리 제안",
    category: "wx",
    model_hint: "Claude Opus 5",
    tags: %w[리팩터링 프론트엔드 설계],
    summary: "비대해진 컴포넌트를 어디서부터 쪼갤지 순서를 잡아 줍니다.",
    usage_notes: "한 번에 다 고치려 하지 말고 받은 순서대로 PR 을 쪼개세요. 상태 관리까지 한꺼번에 바꾸면 리뷰가 불가능해집니다.",
    body: <<~PROMPT
      아래 컴포넌트를 정리하려 합니다. 무엇부터 건드려야 할지 순서를 잡아 주세요.

      ## 코드
      ```
      {{컴포넌트_코드}}
      ```

      ## 맥락
      - 프레임워크: {{예: Nuxt 4 / React 19}}
      - 이 컴포넌트를 쓰는 곳: {{몇_군데서_어떻게}}
      - 테스트 상황: {{있는지_없는지}}

      ## 원하는 답
      1. **지금 이 컴포넌트의 진짜 문제** — 3개 이내. "길다" 말고 무엇이 왜 위험한지.
      2. **쪼개는 순서** — 각 단계는 따로 머지할 수 있어야 하고, 단계마다
         - 무엇을 빼내는지 (이름까지)
         - 화면이 그대로인지 어떻게 확인하는지
         - 예상 난이도
      3. **건드리지 말 것** — 지금 구조에 이유가 있어 보이는 부분과 그 근거.

      상태를 끌어올리거나 내리는 제안을 할 때는, 그렇게 하면 어떤 리렌더가 줄어드는지 함께 적어 주세요.
    PROMPT
  },
  {
    title: "웹 성능 병목 찾기",
    category: "wx",
    model_hint: "Claude Opus 5",
    tags: %w[성능 프론트엔드],
    summary: "Lighthouse 수치와 네트워크 기록을 주면 무엇부터 손볼지 정리해 줍니다.",
    usage_notes: "수치만 주면 일반론이 나옵니다. 어떤 화면인지, 주 사용자가 어떤 기기·회선인지 꼭 적어 주세요.",
    body: <<~PROMPT
      아래 화면이 느립니다. 무엇부터 손봐야 할지 알려 주세요.

      ## 화면
      {{어떤_화면인지}}

      ## 측정값
      ```
      {{Lighthouse_또는_Web_Vitals_수치}}
      ```

      ## 네트워크 / 번들
      ```
      {{큰_리소스_목록이나_번들_분석_결과}}
      ```

      ## 조건
      - 주 사용자 환경: {{예: 안드로이드 중급기, LTE}}
      - 목표: {{예: LCP 2.5초 이내}}

      ## 원하는 답
      1. **병목** — 어떤 지표가 왜 나쁜지, 측정값의 어느 부분이 근거인지.
      2. **손볼 순서** — 효과가 큰 순서대로. 각각
         - 무엇을 바꾸는지
         - 예상 개선 폭 (근거와 함께, 없으면 "측정 필요")
         - 드는 품과 부작용
      3. **효과 없을 것** — 흔히 시도하지만 이 경우엔 의미 없는 것과 그 이유.

      추측으로 숫자를 지어내지 마세요. 자신 없으면 "측정 필요" 라고 적어 주세요.
    PROMPT
  },

  # ---------------- AX ----------------
  {
    title: "프롬프트 진단과 개선",
    category: "ax",
    model_hint: "Claude Opus 5",
    tags: %w[프롬프트 품질],
    summary: "원하는 대로 안 나오는 프롬프트를 진단하고 고쳐 줍니다. 이 위키에 올릴 프롬프트를 다듬을 때도 씁니다.",
    usage_notes: "실패한 출력 예시를 꼭 같이 넣으세요. 그게 없으면 일반적인 조언밖에 못 받습니다.",
    body: <<~PROMPT
      아래 프롬프트가 원하는 대로 동작하지 않습니다. 진단하고 고쳐 주세요.

      ## 지금 쓰는 프롬프트
      ```
      {{프롬프트}}
      ```

      ## 기대한 결과
      {{어떤_출력을_바랐는지}}

      ## 실제로 나온 결과
      ```
      {{실패한_출력}}
      ```

      ## 쓰이는 환경
      - 모델: {{모델명}}
      - 호출 방식: {{한 번 호출 / 대화 / 도구 사용}}
      - 입력 길이: {{대략}}

      ## 원하는 답
      1. **왜 이렇게 나왔는지** — 프롬프트의 어느 문장이 어떤 오해를 만들었는지 짚어 주세요.
      2. **고친 프롬프트** — 전문을 그대로 쓸 수 있게.
      3. **무엇을 바꿨고 왜 바꿨는지** — 변경점마다 한 줄.
      4. **그래도 불안정할 부분** — 프롬프트로는 못 잡는 한계와, 그건 코드로 어떻게 막을지.

      "더 명확하게 쓰세요" 같은 일반론은 쓰지 마세요. 이 프롬프트의 문장을 인용해서 지적해 주세요.
    PROMPT
  },
  {
    title: "응답 품질 평가 기준 만들기",
    category: "ax",
    model_hint: "Claude Opus 5",
    tags: %w[평가 품질 프롬프트],
    summary: "\"괜찮은 것 같다\" 를 사람마다 같게 판단할 수 있는 채점 기준으로 바꿔 줍니다.",
    usage_notes: "여기서 받은 기준으로 팀원 두 명이 같은 출력을 채점해 보세요. 점수가 갈리면 기준이 아직 모호한 겁니다.",
    body: <<~PROMPT
      아래 기능의 응답 품질을 평가할 기준을 만들어 주세요.

      ## 기능
      {{이_기능이_하는_일}}

      ## 좋은 응답의 예
      ```
      {{좋은_예}}
      ```

      ## 나쁜 응답의 예
      ```
      {{나쁜_예}}
      ```

      ## 이 기능에서 절대 나오면 안 되는 것
      {{예: 없는 정책을 지어내기, 고객 정보 노출}}

      ## 원하는 답
      ### 채점 항목
      항목마다 이렇게 적어 주세요.
      - **항목 이름** (배점)
        - 만점: 어떤 상태일 때
        - 0점: 어떤 상태일 때
        - 판단이 갈릴 만한 경계 사례와 그때의 처리

      ### 무조건 실패 조건
      - 하나라도 걸리면 다른 점수와 상관없이 실패인 것

      ### 평가용 입력 10개
      - 쉬운 것 3, 애매한 것 4, 함정 3 으로 나눠서

      항목은 5개를 넘기지 마세요. 사람이 실제로 채점할 수 있어야 합니다.
    PROMPT
  },
  {
    title: "RAG 검색 결과 점검",
    category: "ax",
    model_hint: "Claude Opus 5",
    tags: %w[RAG 검색 디버깅],
    summary: "엉뚱한 문서를 물어 오는 이유를 질의·청크·점수를 보고 짚어 줍니다.",
    usage_notes: "검색된 청크를 점수와 함께 넣어야 판단이 됩니다. 상위 5개면 충분합니다.",
    body: <<~PROMPT
      검색 증강 생성에서 엉뚱한 문서가 걸려 옵니다. 원인을 찾아 주세요.

      ## 사용자 질문
      {{질문}}

      ## 기대한 근거 문서
      {{어떤_문서가_나왔어야_하는지}}

      ## 실제로 검색된 청크 (점수 포함)
      ```
      {{상위_청크들}}
      ```

      ## 색인 방식
      - 청크 크기 / 겹침: {{예: 500토큰, 50토큰 겹침}}
      - 임베딩 모델: {{모델명}}
      - 검색 방식: {{벡터 / 키워드 / 하이브리드}}

      ## 원하는 답
      1. **어디서 어긋났는지** — 다음 중 무엇인지 근거와 함께 고르세요.
         - 질문 표현과 문서 표현이 달라서 (어휘 불일치)
         - 청크가 잘린 자리가 나빠서 (맥락 손실)
         - 색인에 아예 없어서
         - 점수는 맞는데 순위 밖으로 밀려서
      2. **확인 방법** — 5분 안에 가설을 검증할 방법.
      3. **고칠 방법** — 색인을 다시 만들어야 하는지, 질의만 손보면 되는지 구분해서.

      색인을 다시 만들어야만 해결되는 문제라면 그렇다고 분명히 말해 주세요. 비용이 크니까요.
    PROMPT
  },

  # ---------------- MX ----------------
  {
    title: "앱 크래시 원인 추적",
    category: "mx",
    model_hint: "Claude Opus 5",
    tags: %w[디버깅 모바일 장애대응],
    summary: "크래시 로그와 발생 조건을 주면 원인 가설을 확률 순으로 세워 줍니다.",
    usage_notes: "발생 기기·OS 버전 분포를 꼭 넣으세요. 특정 기기에만 나는지가 절반을 가릅니다.",
    body: <<~PROMPT
      아래 크래시의 원인을 추적해 주세요.

      ## 증상
      {{언제_무엇을_하면_죽는지}}

      ## 발생 분포
      - 기기 / OS: {{예: 갤럭시 S22 이하, Android 13 에서만}}
      - 비율: {{예: 해당 화면 진입의 0.3%}}
      - 시작된 버전: {{버전}}

      ## 스택트레이스
      ```
      {{로그}}
      ```

      ## 관련 코드
      ```
      {{코드}}
      ```

      ## 원하는 답
      1. **가설** — 가능성이 높은 순서로 최대 3개. 스택트레이스나 코드의 어느 줄이 근거인지 짚어 주세요.
      2. **확인 방법** — 가설마다, 재현하거나 로그로 확인할 방법.
      3. **수정안** — 가장 유력한 가설이 맞다면 어떻게 고칠지.
      4. **임시 방어** — 정식 수정 전에 크래시만 막을 방법이 있다면.

      메모리·생명주기·스레드 중 무엇의 문제인지는 근거가 있을 때만 단정하세요.
    PROMPT
  },
  {
    title: "스토어 심사 거절 대응",
    category: "mx",
    model_hint: "Claude Sonnet 5",
    tags: %w[배포 모바일],
    summary: "거절 사유를 붙여 넣으면 무엇을 고쳐야 하는지와 회신문 초안을 만들어 줍니다.",
    usage_notes: "회신문은 반드시 사람이 검토하세요. 사실과 다른 약속이 들어가면 다음 심사가 더 어려워집니다.",
    body: <<~PROMPT
      앱 스토어 심사에서 거절당했습니다. 대응 방안을 알려 주세요.

      ## 스토어
      {{App Store / Google Play}}

      ## 거절 사유 (원문 그대로)
      ```
      {{심사팀_회신}}
      ```

      ## 해당 기능 설명
      {{지적받은_기능이_하는_일}}

      ## 원하는 답
      1. **무엇을 문제 삼은 것인지** — 심사 가이드라인의 어느 조항인지, 원문의 어느 부분이 근거인지.
      2. **선택지** — 보통 두세 가지가 있습니다. 각각
         - 무엇을 바꾸는지
         - 통과 가능성과 그 근거
         - 제품에 미치는 영향
      3. **권하는 선택과 이유**
      4. **회신문 초안** — 무엇을 어떻게 바꿨는지 담백하게. 변명이나 과장 없이.

      가이드라인 조항 번호는 확실할 때만 쓰고, 애매하면 "확인 필요" 라고 적어 주세요.
    PROMPT
  },
  {
    title: "릴리스 노트 초안",
    category: "mx",
    model_hint: "Claude Sonnet 5",
    tags: %w[문서화 배포],
    summary: "변경 목록을 넣으면 사용자가 읽을 릴리스 노트로 바꿔 줍니다.",
    usage_notes: "내부 용어가 그대로 나오면 잡아 주세요. \"세그먼트 캐시 개선\" 같은 말은 사용자에게 아무 의미가 없습니다.",
    body: <<~PROMPT
      아래 변경 목록으로 릴리스 노트를 써 주세요.

      ## 이번 버전
      {{버전}}

      ## 변경 목록 (내부 기준)
      {{티켓_목록이나_커밋_로그}}

      ## 읽는 사람
      {{예: 일반 사용자 / 기업 고객 관리자}}

      ## 규칙
      - **사용자가 체감하는 것만** 쓰세요. 내부 구조 변경은 눈에 보이는 결과로 바꿔 쓰거나 빼세요.
      - 기능 추가 → 개선 → 버그 수정 순서로.
      - 한 줄에 하나씩, 동사로 끝나게.
      - 내부 용어·티켓 번호는 쓰지 마세요.
      - 전체 5줄을 목표로. 더 길어질 것 같으면 무엇을 뺄지 알려 주세요.

      ## 출력
      1. 스토어에 올릴 문구
      2. 변경 목록 중 릴리스 노트에서 뺀 것과 그 이유
    PROMPT
  },

  # ---------------- MS ----------------
  {
    title: "장애 상황 고객 공지",
    category: "ms",
    model_hint: "Claude Opus 5",
    tags: %w[장애대응 고객커뮤니케이션],
    summary: "장애 상황을 고객이 이해할 수 있는 공지문으로 바꿔 줍니다.",
    usage_notes: "가장 급할 때 쓰는 프롬프트라 초안을 빨리 받는 게 목적입니다. 복구 시각은 확실하지 않으면 절대 쓰지 마세요.",
    body: <<~PROMPT
      아래 장애 상황을 고객 공지문으로 만들어 주세요.

      ## 지금 상황
      - 언제부터: {{발생_시각}}
      - 무엇이 안 되는지: {{증상}}
      - 영향 범위: {{어떤_고객이_무엇을_못_하는지}}
      - 원인: {{파악됐으면 원인, 아니면 "확인 중"}}
      - 복구 예정: {{확실한_경우에만, 아니면 "미정"}}
      - 우회 방법: {{있으면}}

      ## 보내는 곳
      {{예: 고객사 담당자 이메일 / 서비스 상태 페이지}}

      ## 규칙
      - **첫 줄에 무엇이 안 되는지** 씁니다. 사과는 그 다음입니다.
      - 확실하지 않은 복구 시각을 쓰지 마세요. 대신 "다음 안내 시각" 을 약속하세요.
      - 내부 용어, 서버 이름, 기술적 원인을 그대로 쓰지 마세요.
      - 고객이 지금 할 수 있는 일이 있으면 마지막에 한 줄로.
      - 책임 소재를 흐리는 표현("일부 사용자에게 간헐적으로")은 쓰지 마세요. 숫자로 쓰세요.

      ## 출력
      1. 공지문
      2. 다음 안내 때 채워 넣을 자리 표시
      3. 이 공지를 받고 고객이 물어볼 질문 3개
    PROMPT
  },
  {
    title: "고객 문의 분류와 답변 초안",
    category: "ms",
    model_hint: "Claude Sonnet 5",
    tags: %w[고객지원 분류],
    summary: "들어온 문의를 분류하고 1차 답변 초안까지 만들어 줍니다.",
    usage_notes: "계약·환불처럼 돈이 걸린 건은 초안만 받고 반드시 담당자가 확인하세요.",
    body: <<~PROMPT
      아래 고객 문의를 처리해 주세요.

      ## 문의 내용
      {{고객_문의_원문}}

      ## 고객 정보
      - 고객사: {{고객사명}}
      - 계약 형태: {{예: 엔터프라이즈}}
      - 최근 이력: {{관련된_지난_문의가_있으면}}

      ## 참고 자료
      {{관련_매뉴얼이나_정책_발췌}}

      ## 출력 형식
      ### 분류
      - 유형: 장애 / 사용법 / 기능 요청 / 계약·과금 / 기타
      - 긴급도: 높음 / 보통 / 낮음 (근거 한 줄)
      - 담당: 우리 선에서 처리 / 개발팀 이관 / 영업 이관

      ### 확인해야 할 것
      - 답변 전에 반드시 확인해야 하는 사실 (없으면 "없음")

      ### 답변 초안
      (고객에게 그대로 보낼 수 있는 형태로)

      ### 주의
      - 이 답변에서 잘못 말하면 문제가 될 부분

      ## 규칙
      참고 자료에 없는 정책이나 기한을 지어내지 마세요.
      모르는 건 "확인 후 안내드리겠습니다" 로 두고, 무엇을 확인해야 하는지 위에 적으세요.
    PROMPT
  },
  {
    title: "월간 운영 리포트",
    category: "ms",
    model_hint: "Claude Sonnet 5",
    tags: %w[보고 운영],
    summary: "한 달 운영 기록을 고객사에 보낼 리포트로 정리해 줍니다.",
    usage_notes: "숫자는 반드시 원본 그대로 옮기게 하세요. 어림하거나 반올림하면 고객이 먼저 알아챕니다.",
    body: <<~PROMPT
      아래 기록으로 월간 운영 리포트를 정리해 주세요.

      ## 기간
      {{예: 2026년 9월}}

      ## 고객사
      {{고객사명}}

      ## 이번 달 기록
      {{티켓_통계, 장애_이력, 작업_내역 등 두서없이}}

      ## 출력 형식
      ### 한 달 요약
      (세 줄 이내. 고객 담당자가 이것만 읽어도 되게)

      ### 서비스 안정성
      - 가동률 / 장애 건수 / 총 중단 시간
      - 장애가 있었다면 각각: 언제, 무엇이, 얼마나, 어떻게 조치했는지

      ### 문의 처리
      - 접수 / 처리 완료 / 평균 응답 시간
      - 많이 들어온 문의 유형 상위 3개

      ### 이번 달 작업
      - 무엇을 했고 고객에게 어떤 도움이 되는지

      ### 다음 달 계획과 협의 필요 사항

      ## 규칙
      - 숫자는 입력에 있는 그대로 옮기세요. 없는 수치는 만들지 말고 "집계 필요" 로 두세요.
      - 나쁜 숫자를 감추지 마세요. 대신 무엇을 하고 있는지 옆에 적으세요.
    PROMPT
  },

  # ---------------- PMO ----------------
  {
    title: "프로젝트 주간 상태 보고",
    category: "pmo",
    model_hint: "Claude Sonnet 5",
    tags: %w[보고 프로젝트관리],
    summary: "각 팀에서 올라온 진행 상황을 이해관계자가 읽을 상태 보고로 묶어 줍니다.",
    usage_notes: "각 팀 보고를 그대로 붙여 넣으면 됩니다. 상태가 '주의'로 바뀌는 근거를 꼭 확인하세요.",
    body: <<~PROMPT
      아래 내용으로 프로젝트 주간 상태 보고를 작성해 주세요.

      ## 프로젝트
      - 이름: {{프로젝트명}}
      - 목표 일정: {{마감일}}
      - 이번 주차: {{예: 12주차 / 전체 20주}}

      ## 각 팀 보고
      {{팀별_진행_상황_원문}}

      ## 읽는 사람
      {{예: 스폰서 / 고객사 PM / 경영진}}

      ## 출력 형식
      ### 전체 상태
      🟢 정상 / 🟡 주의 / 🔴 위험 — 한 줄 근거

      ### 이번 주 진척
      - 완료된 것 (무엇이 끝났고 그래서 무엇이 가능해졌는지)

      ### 일정
      - 계획 대비 현재 / 다음 마일스톤과 도달 가능성

      ### 리스크와 이슈
      | 내용 | 영향 | 대응 | 담당 | 기한 |
      |---|---|---|---|---|

      ### 결정이 필요한 것
      - 무엇을 / 누가 / 언제까지 (없으면 "없음")

      ## 규칙
      - 상태를 🟡 이상으로 올릴 때는 반드시 근거를 숫자나 사실로 적으세요.
      - 입력에 없는 진척률을 추정해서 쓰지 마세요.
      - 나쁜 소식을 뒤에 숨기지 마세요. 보고의 목적은 도움을 받는 것입니다.
    PROMPT
  },
  {
    title: "리스크 정리",
    category: "pmo",
    model_hint: "Claude Opus 5",
    tags: %w[리스크 프로젝트관리],
    summary: "프로젝트 상황을 주면 아직 드러나지 않은 리스크까지 끌어내 정리해 줍니다.",
    usage_notes: "킥오프 직후와 중요한 마일스톤 전에 한 번씩 돌려 보면 좋습니다. 이미 아는 리스크만 나오면 입력이 부족한 겁니다.",
    body: <<~PROMPT
      아래 프로젝트의 리스크를 정리해 주세요.

      ## 프로젝트 개요
      {{무엇을_언제까지_누구와}}

      ## 지금 알고 있는 것
      - 확정된 범위: {{범위}}
      - 아직 안 정해진 것: {{미정_사항}}
      - 투입 인력: {{인원과_기간}}
      - 외부 의존: {{협력사, 고객사 작업, 외부 API 등}}

      ## 이미 파악한 리스크
      {{있으면}}

      ## 원하는 답
      ### 리스크 목록
      항목마다 이렇게 적어 주세요.
      - **리스크** — 무엇이 어떻게 잘못될 수 있는지 (막연하게 "일정 지연" 말고 구체적으로)
        - 발생 가능성: 높음/보통/낮음 — 그렇게 본 근거
        - 영향: 무엇이 얼마나 (가능하면 일수나 금액으로)
        - 조기 경보: 이 리스크가 현실이 되기 전에 먼저 보이는 신호
        - 대응: 미리 할 일 / 터졌을 때 할 일

      ### 이 프로젝트에서 가장 위험한 하나
      - 무엇이고, 왜 그렇게 보는지

      ## 규칙
      - 입력에 드러나지 않았지만 이런 구성에서 흔히 터지는 것도 포함하세요. 대신 추측이라고 표시하세요.
      - 리스크는 7개를 넘기지 마세요. 관리할 수 있는 수여야 합니다.
    PROMPT
  },
  {
    title: "회의록 정리와 액션 아이템 추출",
    category: "pmo",
    model_hint: "Claude Sonnet 5",
    tags: %w[회의 요약 협업],
    summary: "녹취나 메모를 붙여 넣으면 결정 사항과 할 일을 분리해 줍니다.",
    usage_notes: "전사에서 가장 많이 쓰는 프롬프트입니다. 담당자 이름이 녹취에 없으면 비워 두게 하는 게 핵심이에요.",
    body: <<~PROMPT
      아래 회의 기록을 정리해 주세요.

      ## 회의 정보
      - 주제: {{회의_주제}}
      - 일시: {{날짜}}
      - 참석자: {{참석자_명단}}

      ## 기록
      {{녹취록_또는_메모}}

      ## 출력 형식
      ### 한 줄 요약
      (이 회의에서 결국 무엇이 정해졌는지 한 문장)

      ### 결정된 것
      - 결정 내용 / 결정한 사람 / 근거

      ### 아직 안 정해진 것
      - 쟁점 / 각 입장 / 언제까지 정해야 하는지

      ### 액션 아이템
      | 할 일 | 담당 | 기한 |
      |---|---|---|

      ### 다음 회의에서 다룰 것
      -

      ## 규칙
      - 기록에 없는 담당자나 기한은 **절대 지어내지 마세요.** 비워 두고 `미정` 이라고 적으세요.
      - 잡담과 곁가지는 빼고, 결정과 할 일에만 집중하세요.
      - 누가 한 말인지가 중요한 발언은 "(이름)" 을 붙여 주세요.
    PROMPT
  },

  # ---------------- 경영지원팀 ----------------
  {
    title: "사내 공지문 다듬기",
    category: "biz-support",
    model_hint: "Claude Haiku 4.5",
    tags: %w[공지 커뮤니케이션],
    summary: "초안을 넣으면 사람들이 실제로 읽는 공지로 바꿔 줍니다.",
    usage_notes: "짧은 작업이라 Haiku 로 충분합니다. 급한 공지일수록 이걸 한 번 거치면 문의가 줄어요.",
    body: <<~PROMPT
      아래 공지 초안을 다듬어 주세요.

      ## 초안
      {{초안}}

      ## 대상
      {{예: 전사 / 특정 팀 / 신규 입사자}}

      ## 올리는 곳
      {{예: 슬랙 전사 채널 / 사내 메일}}

      ## 규칙
      - 첫 줄만 읽어도 무슨 일인지 알 수 있게.
      - 사람들이 궁금해할 것(언제부터, 뭘 해야 하는지, 안 하면 어떻게 되는지)을 빠뜨리지 마세요.
      - 문단 대신 짧은 줄바꿈과 불릿을 쓰세요.
      - 이모지는 많아야 2개.
      - 마지막에 질문 받을 창구를 한 줄로.

      다듬은 뒤, 이 공지를 보고 나올 법한 질문 3개를 예상해 주세요.
      그 질문이 나온다면 공지에 빠진 게 있다는 뜻입니다.
    PROMPT
  },
  {
    title: "채용 공고 초안",
    category: "biz-support",
    model_hint: "Claude Opus 5",
    tags: %w[채용 문서화],
    summary: "직무 정보를 주면 지원하고 싶어지는 채용 공고를 써 줍니다.",
    usage_notes: "현업 팀장이 준 내용을 그대로 넣으세요. 다만 연봉·복지는 확정된 것만 적게 하세요.",
    body: <<~PROMPT
      아래 직무의 채용 공고를 써 주세요.

      ## 직무
      - 포지션: {{직무명}}
      - 소속 팀: {{팀과_하는_일}}
      - 연차: {{예: 3년 이상}}

      ## 이 사람이 할 일
      {{현업에서_받은_설명}}

      ## 꼭 필요한 역량 / 있으면 좋은 역량
      {{구분해서}}

      ## 팀 상황
      - 팀 규모와 구성: {{}}
      - 쓰는 기술 / 도구: {{}}
      - 지금 팀이 풀고 있는 문제: {{}}

      ## 규칙
      - **왜 이 자리가 생겼는지**부터 쓰세요. 지원자가 가장 궁금해하는 것입니다.
      - "열정 있는", "성장하는" 같은 말은 쓰지 마세요. 구체적인 사실로 대체하세요.
      - 자격 요건은 정말 필요한 것만. 길수록 좋은 지원자가 스스로 걸러집니다.
      - 입력에 없는 연봉·복지·근무 형태를 지어내지 마세요. `{{확인 필요}}` 로 비워 두세요.

      ## 출력
      1. 공고 전문
      2. 현업에 되물어야 할 것 (공고를 쓰다 보니 빈 정보)
    PROMPT
  },
  {
    title: "사내 규정 문의 답변",
    category: "biz-support",
    model_hint: "Claude Opus 5",
    tags: %w[규정 문서화],
    summary: "규정 원문을 근거로 문의에 답하는 초안을 만들어 줍니다.",
    usage_notes: "규정 해석이 갈릴 수 있는 건은 반드시 사람이 확인하세요. 이 프롬프트는 근거 조항을 찾아 주는 데까지가 역할입니다.",
    body: <<~PROMPT
      구성원 문의에 답할 초안을 만들어 주세요.

      ## 문의
      {{질문_원문}}

      ## 관련 규정 원문
      ```
      {{규정_발췌}}
      ```

      ## 출력 형식
      ### 답변 초안
      (문의한 사람에게 그대로 보낼 수 있는 형태로)

      ### 근거
      - 규정의 어느 조항인지, 원문을 그대로 인용

      ### 확인이 필요한 부분
      - 규정만으로는 판단이 안 되는 지점과, 누구에게 물어야 하는지

      ## 규칙
      - **규정 원문에 없는 내용은 절대 답하지 마세요.** 없으면 "규정에 명시되어 있지 않다" 고 적고
        확인이 필요한 부분에 옮기세요.
      - 해석이 갈릴 수 있으면 갈린다고 쓰세요. 한쪽으로 단정하지 마세요.
      - 금액·일수·기한은 원문 그대로 옮기세요.
    PROMPT
  },

  # ---------------- 대표이사실 ----------------
  {
    title: "경영 보고 요약",
    category: "ceo-office",
    model_hint: "Claude Opus 5",
    tags: %w[요약 경영],
    summary: "긴 보고서를 의사결정에 필요한 만큼으로 줄여 줍니다.",
    usage_notes: "'무엇을 결정해야 하는지'를 적는 게 제일 중요합니다. 그냥 요약해 달라고 하면 밋밋한 개요만 나옵니다.",
    body: <<~PROMPT
      아래 보고서를 경영 판단에 필요한 만큼으로 줄여 주세요.

      ## 지금 결정해야 하는 것
      {{이_보고서를_왜_읽는지, 무엇을_정해야_하는지}}

      ## 보고서
      {{본문}}

      ## 출력 형식
      ### 핵심 (3줄)

      ### 결정에 직접 닿는 내용
      - (위에 적은 판단과 관련된 것만. 숫자는 원문 그대로)

      ### 근거의 세기
      - 무엇이 확인된 사실이고, 무엇이 추정이고, 무엇이 희망인지 구분해서

      ### 이 보고서가 말하지 않는 것
      - 빠져 있거나 약한 근거, 암묵적 전제
      - 반대편에서 이 보고서를 읽으면 어디를 칠지

      ### 되물어야 할 질문 3개

      ## 규칙
      - 원문에 없는 내용은 넣지 마세요.
      - 숫자는 어림하지 말고 그대로 옮기세요.
      - 보고서의 결론에 동의하는지 여부는 쓰지 마세요. 판단은 읽는 사람이 합니다.
    PROMPT
  },
  {
    title: "대외 발표문 초안",
    category: "ceo-office",
    model_hint: "Claude Opus 5",
    tags: %w[커뮤니케이션 대외],
    summary: "전하고 싶은 메시지를 자리에 맞는 발표문으로 만들어 줍니다.",
    usage_notes: "초안만 받고 대표님 말투로 반드시 다듬으세요. 그대로 읽으면 티가 납니다.",
    body: <<~PROMPT
      아래 자리에서 할 발표문 초안을 써 주세요.

      ## 자리
      - 무슨 자리: {{예: 사업 설명회 / 전사 타운홀 / 파트너사 행사}}
      - 듣는 사람: {{누가_몇_명}}
      - 분량: {{예: 5분}}

      ## 전하고 싶은 것
      - 핵심 메시지 한 줄: {{이것만_기억했으면_하는_것}}
      - 배경: {{맥락}}
      - 쓸 수 있는 사실·숫자: {{}}

      ## 듣는 사람이 지금 가진 생각
      {{예: 이번 조직 개편에 불안해하고 있음}}

      ## 규칙
      - **핵심 메시지를 처음과 끝에 한 번씩.** 가운데는 근거입니다.
      - 숫자는 입력에 있는 것만. 없으면 `{{확인 필요}}` 로 두세요.
      - 듣는 사람이 속으로 하고 있을 질문을 먼저 꺼내서 답하세요. 피하면 신뢰를 잃습니다.
      - 구호나 미사여구 대신 구체적인 사실로 설득하세요.
      - 읽었을 때 {{분량}} 안에 끝나는 길이로.

      ## 출력
      1. 발표문
      2. 이 발표 뒤에 나올 법한 껄끄러운 질문 3개와, 각각 어떻게 답할지
    PROMPT
  },
  {
    title: "이사회 문답 준비",
    category: "ceo-office",
    model_hint: "Claude Opus 5",
    tags: %w[경영 보고],
    summary: "안건을 주면 이사회에서 나올 질문과 답변 방향을 미리 정리해 줍니다.",
    usage_notes: "예상 질문이 물렁하게 나오면 '가장 비판적인 이사 관점으로'라고 덧붙이세요.",
    body: <<~PROMPT
      이사회 안건에 대한 예상 문답을 준비해 주세요.

      ## 안건
      {{안건_내용}}

      ## 이 안건의 배경
      {{왜_지금_이_안건이_올라가는지}}

      ## 뒷받침하는 숫자
      {{실적, 예산, 전망 등}}

      ## 이사회 구성
      {{예: 사내 2인, 사외 3인 (재무 배경 1명)}}

      ## 출력 형식
      항목마다 이렇게 적어 주세요.
      - **예상 질문** — 누가 왜 물을 것 같은지
        - 답변 방향: (핵심만 3줄 이내)
        - 근거로 쓸 숫자: (입력에 있는 것만)
        - 이 답변의 약점: 여기서 더 파고들면 무엇이 곤란해지는지

      마지막에 **가장 답하기 어려운 질문 하나**를 꼽고, 왜 어려운지 적어 주세요.

      ## 규칙
      - 우호적인 질문 말고 **비판적인 질문** 위주로 8개 이상.
      - 입력에 없는 숫자로 답을 만들지 마세요. 필요한데 없으면 "이 숫자를 준비해야 함" 으로 표시하세요.
    PROMPT
  },

  # ---------------- 기업부설연구소 ----------------
  {
    title: "기술 자료 검토",
    category: "rnd",
    model_hint: "Claude Opus 5",
    tags: %w[리서치 요약],
    summary: "논문이나 기술 문서를 우리가 쓸 수 있는지 관점으로 정리해 줍니다.",
    usage_notes: "'우리 상황'을 적을수록 결과가 쓸모 있어집니다. 데이터 규모와 지연 시간 제약을 꼭 넣으세요.",
    body: <<~PROMPT
      아래 기술 자료를 검토해 주세요.

      ## 우리 상황
      - 풀려는 문제: {{문제}}
      - 지금 방식과 그 한계: {{현재}}
      - 제약: {{데이터 규모, 지연 시간, 비용, 인력}}

      ## 자료
      {{논문_또는_기술_문서}}

      ## 출력 형식
      ### 한 줄 요약
      (이 자료가 주장하는 것)

      ### 핵심 아이디어
      - 기존 방식과 무엇이 다른지, 왜 그게 통하는지

      ### 검증된 조건
      - 저자가 어떤 환경·데이터에서 실험했는지
      - 우리 상황과 다른 지점

      ### 우리에게 적용 가능한가
      - 가능성: 높음 / 보통 / 낮음 — 근거와 함께
      - 적용한다면 무엇부터 실험해 볼지
      - 걸림돌

      ### 이 자료가 말하지 않는 것
      - 실패 사례, 계산 비용, 재현성

      ## 규칙
      - 자료에 없는 수치를 만들지 마세요.
      - 저자의 주장과 실제로 측정된 결과를 구분해서 적으세요.
    PROMPT
  },
  {
    title: "실험 설계 검토",
    category: "rnd",
    model_hint: "Claude Opus 5",
    tags: %w[실험 방법론],
    summary: "실험 계획을 주면 결론을 못 내리게 만들 구멍을 미리 짚어 줍니다.",
    usage_notes: "실험을 돌리기 전에 거치세요. 돌린 뒤에 발견하면 처음부터 다시 해야 합니다.",
    body: <<~PROMPT
      아래 실험 설계를 검토해 주세요.

      ## 알고 싶은 것
      {{이_실험으로_무엇을_판단하려는지}}

      ## 가설
      {{가설}}

      ## 설계
      - 비교 대상: {{무엇과_무엇을}}
      - 데이터: {{출처, 규모, 분할 방식}}
      - 측정 지표: {{}}
      - 통제할 변수: {{}}

      ## 원하는 답
      1. **이 설계로 가설을 검증할 수 있는가** — 안 된다면 왜 안 되는지.
      2. **결론을 흐릴 구멍** — 앞에 있을수록 치명적입니다.
         - 비교 대상이 공정한가 (조건이 한 가지만 다른가)
         - 데이터가 새고 있지 않은가 (train/test 오염)
         - 지표가 알고 싶은 것을 재고 있는가
         - 우연으로 나올 수 있는 차이인가 (표본 수, 반복 횟수)
      3. **고친 설계** — 구멍마다 어떻게 메울지.
      4. **실험 전에 정해 둘 것** — 어떤 결과가 나오면 가설을 기각할지 미리 적어 두게.

      결과를 보고 나서 기준을 바꾸면 실험이 아니게 됩니다. 그 점을 특히 봐 주세요.
    PROMPT
  },
  {
    title: "연구개발 과제 보고서 초안",
    category: "rnd",
    model_hint: "Claude Opus 5",
    tags: %w[문서화 과제],
    summary: "연구 기록을 과제 보고서 형식으로 옮겨 줍니다.",
    usage_notes: "제출 기관 양식에 맞춰 항목 이름을 바꿔 쓰세요. 실패한 시도도 적는 게 중요합니다.",
    body: <<~PROMPT
      아래 기록으로 연구개발 과제 보고서 초안을 써 주세요.

      ## 과제
      - 과제명: {{과제명}}
      - 기간: {{기간}}
      - 목표: {{당초_목표}}

      ## 이 기간에 한 일
      {{실험_기록, 개발_내역, 회의록 등 두서없이}}

      ## 결과
      {{수치와_산출물}}

      ## 출력 형식
      ### 연구 목표 대비 달성도
      - 목표별로: 달성 / 부분 달성 / 미달 — 근거가 되는 수치와 함께

      ### 수행 내용
      - 무엇을 왜 했는지, 시간 순이 아니라 주제별로

      ### 결과 및 고찰
      - 얻은 것과, 그것이 목표에 어떻게 닿는지
      - **시도했으나 잘 안 된 것과 그 이유** (여기가 다음 과제의 출발점입니다)

      ### 향후 계획

      ## 규칙
      - 기록에 없는 수치를 만들지 마세요. 필요한데 없으면 "측정 필요" 로 표시하세요.
      - 달성도를 좋게 보이려고 목표를 슬쩍 바꿔 쓰지 마세요. 미달은 미달로 적고 이유를 쓰세요.
      - 전문 용어는 처음 나올 때 한 번 풀어 주세요. 심사자가 우리 분야 전문가가 아닐 수 있습니다.
    PROMPT
  }
].freeze

PROMPTS.each do |attributes|
  author = members[TEAM_OWNER.fetch(attributes[:category])] || admin

  prompt = Prompt.find_or_initialize_by(title: attributes[:title])
  prompt.assign_attributes(
    category: categories.fetch(attributes[:category]),
    author: author,
    last_editor: author,
    summary: attributes[:summary],
    body: attributes[:body].strip,
    usage_notes: attributes[:usage_notes],
    model_hint: attributes[:model_hint],
    status: :published
  )
  prompt.tag_names = attributes[:tags]
  prompt.save!
  prompt.record_version!(editor: author, change_note: "최초 작성") if prompt.versions.empty?
end

unless PRODUCTION
  {
    "웹 접근성 점검" => %w[central-gov local-gov],
    "장애 상황 고객 공지" => %w[finance public],
    "월간 운영 리포트" => %w[banking],
    "고객 문의 분류와 답변 초안" => %w[insurance],
    "이사회 문답 준비" => %w[finance],
    "연구개발 과제 보고서 초안" => %w[defense manufacturing],
    "기술 자료 검토" => %w[healthcare semiconductor]
  }.each do |title, slugs|
    prompt = Prompt.find_by(title: title)
    prompt&.update!(domains: slugs.filter_map { |slug| domains[slug] })
  end
end

# 개발에서는 목록 정렬이 밋밋해 보이지 않도록 사용 흔적을 조금 남겨 둔다.
# 운영에서는 실제로 쓴 만큼만 쌓여야 하므로 건드리지 않는다.
unless PRODUCTION
  Prompt.find_each do |prompt|
    next if prompt.copy_count.positive?

    prompt.update_columns(copy_count: rand(3..48), view_count: rand(20..260))
  end
end

puts "완료: 카테고리 #{Category.count}개 / 도메인 #{Domain.count}개 / 구성원 #{User.count}명 / 프롬프트 #{Prompt.count}개 / 태그 #{Tag.count}개"
Category.ordered.each do |category|
  puts "  #{category.name.ljust(12)} #{category.prompts.count}개"
end
puts
if PRODUCTION
  puts "관리자 계정"
  puts "  #{ADMIN_EMAIL}"
  if ENV["SEED_ADMIN_PASSWORD"].blank?
    puts "  비밀번호: #{ADMIN_PASSWORD}"
    puts "  * 이 비밀번호는 지금 한 번만 보여집니다. 따로 적어 두세요."
  else
    puts "  비밀번호: 넘겨주신 값 그대로"
  end
else
  puts "로그인 계정 (개발용)"
  puts "  관리자  #{ADMIN_EMAIL} / #{ADMIN_PASSWORD}"
  puts "  일반    haneul.lee@soundmind.example / #{DEFAULT_PASSWORD}"
end
