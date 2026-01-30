# Session Retrospective: Gemini CLI & User Collaboration

**Date:** 2026-01-30
**Topic:** OCI Terraform Infrastructure Construction (Compute & Autonomous DB)

이 문서는 사용자와 Gemini CLI Agent가 협업하여 OCI 인프라를 구축한 과정, 발생한 이슈, 그리고 해결책을 회고(Retrospective)하는 목적으로 작성되었습니다.

## 1. 개요 (Overview)
- **목표:** OCI 춘천 리전에 Terraform을 활용하여 확장 가능하고 안전한 IaaS/PaaS 환경 구축.
- **성과:**
    1.  ARM 기반 Compute 인스턴스 배포 및 상태 제어 자동화.
    2.  ECPU 기반 Autonomous Database (26ai) 생성 성공.
    3.  보안/인증 체계 고도화 (Config 파일 참조, Git Ignore 적용).
    4.  표준화된 문서 관리 및 GitHub 연동 체계 수립.

## 2. 주요 성공 및 협업 내역 (Achievements)

### 2.1 인프라 모듈화 및 동적 구성
- **요청:** "순번을 지정해서 동적 구조로 바꿔줘."
- **실행:** `for_each` 구문을 도입하여 `variables.tf`의 숫자(`instance_count`)만 변경하면 인스턴스가 증설되는 유연한 구조를 만들었습니다.
- **결과:** 유지보수성이 높은 코드 베이스 확보.

### 2.2 보안 리팩토링 (Security Refactoring)
- **요청:** "키 정보를 코드에 입력하지 말고 `~/.oci/config`를 참고해줘."
- **실행:**
    - `provider.tf`에서 인증 변수 제거 및 프로필 참조 방식 전환.
    - `terraform.tfvars` 및 `variables.tf`에서 민감 변수(`tenancy_ocid` 등) 제거.
    - 코드 내에서 테넌시 ID가 필요할 때 `parent_compartment_id`를 재활용하거나 데이터 소스를 활용하는 방식으로 우회하여 의존성 제거.
- **결과:** 코드 내 민감 정보(Hardcoded Secrets) Zero화 달성.

### 2.3 운영 자동화 (Operational Logic)
- **요청:** "test-1은 running, test-2만 stop 상태로 두고 싶어."
- **실행:** Terraform의 삼항 연산자 조건문(`each.key == "1" ? "RUNNING" : "STOPPED"`)을 `compute.tf`에 적용.
- **결과:** 코드를 통한 정교한 리소스 상태(State) 제어 구현.

### 2.4 표준화 및 거버넌스 (Governance)
- **요청:** "다음에 다른 환경에서도 적용할 수 있게 LLM이 참고할 파일을 만들어 줘."
- **실행:**
    - `GEMINI_INSTRUCTIONS.md`: Agent 행동 강령 (승인 절차, 보안 원칙).
    - `LLM_TERRAFORM_PATTERN.md`: Terraform 표준 설계 패턴 정의.
- **결과:** 향후 작업의 일관성 및 AI 협업 효율성 증대.

## 3. 트러블슈팅 및 실패 극복 (Troubleshooting)

### 3.1 GitHub 연동 인증 실패
- **상황:** `ARCHITECTURE.md`를 GitHub에 푸시하는 과정에서 인증 오류 발생.
- **원인:**
    1.  비밀번호 인증 방식 중단(Deprecated).
    2.  Fine-grained PAT(Token)의 권한 부족 (Contents: Read-only).
- **해결:** 사용자가 **Contents: Read and write** 권한이 부여된 새로운 토큰을 발급받아 제공함으로써 해결.

### 3.2 Autonomous Database 버전 및 모델 호환성 이슈
- **상황:** ADB 생성 시 OCPU 모델을 사용하여 `26ai` 및 `23ai` 버전 생성 시도 시 `409 IncorrectState` 오류 반복 발생.
- **분석:** 현재 테넌시 혹은 리전의 OCPU 모델에서는 최신 버전(`26ai`) 기능이 활성화되지 않았거나 제약이 있음을 확인.
- **해결 (Pivot):** 
    1. 컴퓨트 모델을 기존 **OCPU**에서 최신 과금/성능 모델인 **ECPU**로 변경.
    2. ECPU 모델 적용 후, 다시 최신 버전인 **26ai**로 생성을 시도하여 최종 성공.
- **교훈:** OCI의 최신 DB 버전은 특정 컴퓨트 모델(ECPU)과 결합될 때 우선적으로 지원될 수 있음을 확인하고 유연하게 전략을 수정하여 목표를 달성함.

### 3.3 Dev Note 방향성 재정립
- **상황:** 초기 Dev Note에 인스턴스 상태(Running/Stopped)와 같은 변동성 데이터를 기록함.
- **피드백:** "tfstate가 있는데 굳이 노트에 상태를 적을 필요가 있을까?" (사용자의 날카로운 지적)
- **수정:** 노트의 성격을 '상태 기록'에서 **'변경 이력(History) 및 의도 기록'**으로 전면 수정하여 중복을 제거하고 관리 효율을 높임.

## 4. 결론 (Conclusion)
이번 세션은 단순한 리소스 생성을 넘어, **"보안", "표준화", "운영 효율성"**을 고려한 프로덕션 레벨의 인프라 코드를 완성하는 과정이었습니다. 특히 사용자의 명확한 피드백(보안 우려, 문서화 방향성) 덕분에 Gemini CLI Agent는 더 나은 결과물을 도출할 수 있었습니다.

- **작성자:** Gemini CLI Agent
- **작성일:** 2026-01-30
