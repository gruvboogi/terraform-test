# Terraform 개발 노트: OCI 인프라 구축 프로젝트

## [2026-01-28] 프로젝트 시작 및 네트워크 구축

### 1. 작업 개요
- **목표:** OCI(Oracle Cloud Infrastructure) 춘천 리전(`ap-chuncheon-1`)에 테라폼 기반 네트워크 인프라 구축
- **범위:** VCN, Subnet, Gateway, Route Table 등 기본 네트워크 구성

### 2. 주요 수행 내역

#### 2.1 기초 설정
- **인증 구성:** `~/.oci/config` 파일을 참조하는 API 키 방식 적용
- **프로바이더 업데이트:** `hashicorp/oci` → `oracle/oci` (최신 권장)

#### 2.2 네트워크 인프라 구축
- **VCN:** `192.0.0.0/16` 대역 생성
- **Public Subnet:** `192.0.1.0/24` (Internet Gateway 연결)
- **Private Subnet:** 생성 및 테스트 후 코드 주석 처리(삭제)하여 리소스 관리 테스트 수행

#### 2.3 테라폼 워크플로우 정립
- `init` -> `plan` -> `apply` 기반의 배포 프로세스 검증 완료

---

## [2026-01-30] 인프라 확장 및 운영 고도화

### 1. 작업 개요
- **목표:** 컴퓨트 및 데이터베이스 리소스 배포, 보안 최적화 및 아키텍처 문서화

### 2. 주요 수행 내역

#### 2.1 컴퓨트 및 데이터베이스 구축
- **Compute:** ARM 기반 인스턴스 2대 배포 및 조건부 상태 제어(Running/Stopped) 적용
- **Autonomous Database:** `oracle-db.tf`를 분리하여 생성. 최신 **ECPU 모델** 및 **Oracle Database 26ai** 버전 적용 성공

#### 2.2 보안 및 운영 최적화
- **Refactoring:** 코드 내 민감 정보(`tenancy_ocid` 등)를 완전히 제거하고 동적 데이터 소스로 전환
- **Governance:** 프로젝트 전용 지침(`GEMINI_INSTRUCTIONS.md`) 및 표준 패턴(`LLM_TERRAFORM_PATTERN.md`) 수립

#### 2.3 문서화 및 형상 관리
- **Visualization:** Mermaid를 활용한 아키텍처 다이어그램(`ARCHITECTURE.md`) 자동 생성 및 업데이트
- **GitHub:** Fine-grained PAT를 통해 원격 저장소 연동 및 문서 푸시 완료
- **Security:** `.gitignore` 도입으로 개인키 및 상태 파일의 외부 노출 원천 차단

---
*본 노트는 Gemini CLI Agent에 의해 자동 생성 및 업데이트되었습니다.*
*참고: 상세한 리소스 상태 및 속성은 `terraform.tfstate` 파일을 참조하십시오.*
