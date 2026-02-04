# Gemini CLI Instructions for Terraform OCI Project

이 파일은 Gemini CLI Agent가 이 프로젝트(`terraform-oci`)에서 작업할 때 준수해야 할 핵심 원칙과 규칙을 정의합니다.

## 1. 프로젝트 개요 및 아키텍처
- **목표:** Oracle Cloud Infrastructure (OCI) 춘천 리전(`ap-chuncheon-1`)에 Terraform을 사용하여 IaaS 인프라 구축.
- **주요 리소스:** VCN, Public/Private Subnet, ARM 기반 Compute Instances (`VM.Standard.A1.Flex`).
- **아키텍처 참조:** `ARCHITECTURE.md` (Mermaid 다이어그램 포함).

## 2. 핵심 원칙 (Core Mandates)

### 2.1 상태 관리 (State Management)
- **Source of Truth:** 인프라의 현재 상태(IP, ID, Running/Stopped 등)는 오직 `terraform.tfstate`를 통해서만 확인한다.
- **문서화 원칙:** `TERRAFORM_DEV_NOTES.md`에는 변동되는 상태 값이 아닌, **작업의 목적, 변경 내역, 의사결정의 이유**만을 기록한다.

### 2.2 보안 및 인증 (Security & Auth)
- **OCI 인증:** 코드 내에 키 정보를 하드코딩하지 않는다. `provider.tf`는 `~/.oci/config` (DEFAULT 프로필)를 참조하도록 설정한다.
- **SSH 키:** 인스턴스 접속용 키는 `./ssh-key/` 폴더 내의 파일을 사용하며, `file()` 함수로 참조한다.
- **민감 정보:** `*.key` (Private Key), `*.tfvars`, `*.tfstate` 파일은 `.gitignore`에 등록하여 절대 외부로 유출되지 않도록 한다.

### 2.3 Git 및 저장소 정책 (Git Repository Policy) - CRITICAL
- **Markdown Only:** 원격 저장소(GitHub)에는 오직 `*.md` (문서) 파일만 푸시한다.
- **Push 금지:** Terraform 코드(`*.tf`), 상태 파일(`*.tfstate`), 설정 파일, 키, 이미지 등은 **절대** 원격 저장소에 올리지 않는다. 로컬에서만 관리한다.
- **Commit 수칙:**
    - `git add .` 사용을 **엄격히 금지**한다. (의도치 않은 파일 포함 방지)
    - 반드시 `git add *.md` 또는 `git add <파일명>`을 사용하여 명시적으로 파일만 스테이징한다.
    - 커밋 전 `git status`를 통해 불필요한 파일이 포함되지 않았는지 2차 검증한다.

## 3. 작업 워크플로우 (Workflow)

1.  **사전 검증:** 모든 리소스 변경 전 반드시 `terraform plan`을 수행하여 변경 사항을 시뮬레이션한다.
2.  **승인 절차 (CRITICAL):** `terraform apply` 명령은 **반드시 `terraform plan` 결과를 보여주고 사용자의 명시적인 "승인" 또는 "실행해"라는 답변을 받은 후에만** 실행한다.
    - **절대 금지:** 사용자가 명령어에 직접 포함시키지 않는 한, Agent가 임의로 `-auto-approve` 플래그를 사용해서는 안 된다.
3.  **리소스 생성/수정:**
    - 가능한 한 `variables.tf`를 통해 매개변수화(Parameterization)한다.
    - 리소스 수량 변경 등은 `count`나 `for_each`를 활용하여 동적으로 구성한다.
3.  **검증:** 생성 후 SSH 접속 테스트 등을 통해 정상 작동을 확인한다.
4.  **이력 기록:** 작업이 완료되면 `TERRAFORM_DEV_NOTES.md`에 날짜별 섹션을 추가(또는 갱신)하여 작업 내용을 요약 기록한다.

## 4. 파일 구조 가이드
- `main.tf`: Provider 설정 외 공통/기본 리소스. (현재는 Provider 설정은 `provider.tf`로 분리됨)
- `provider.tf`: OCI Provider 설정.
- `network.tf`: VCN, Subnet, Gateway, Route Table 등 네트워크 관련 리소스.
- `compute.tf`: Compute Instance, Volume 등 컴퓨트 리소스.
- `oracle-db.tf`: Autonomous Database (ADB) 관련 리소스.
- `variables.tf`: 변수 정의.
- `terraform.tfvars`: 변수 값 할당 (민감 정보 제외).
