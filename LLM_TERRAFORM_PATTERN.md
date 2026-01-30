# LLM Reference: Terraform Standard Project Structure

이 문서는 Terraform 프로젝트를 시작할 때 LLM(AI Agent)이 따라야 할 **표준 파일 구조와 설계 패턴**을 정의합니다. 
본 프로젝트(`terraform-oci`)에서 검증된 **계층별/서비스별 분리 원칙**을 기반으로 합니다.

## 1. 아키텍처 철학 (Architecture Philosophy)
- **Separation of Concerns:** 모든 리소스를 `main.tf`에 몰아넣지 않고, **인프라 계층(Layer)과 서비스 성격**에 따라 파일을 분리한다.
- **Security First:** 인증 정보는 코드가 아닌 환경 설정(Config/Env)에 위임하며, 민감 정보는 철저히 격리한다.
- **Traceability:** 작업의 의도와 이력을 별도의 문서로 관리한다.

## 2. 표준 파일 구조 (Standard File Structure)

프로젝트 루트에는 다음과 같은 파일 구성을 기본으로 한다:

### 2.1 설정 및 코어 (Configuration & Core)
- **`provider.tf`**:
    - Provider 정의, 버전 제약(`required_providers`), Backend 설정.
    - **규칙:** 인증 정보(Key, Token)를 하드코딩하지 않고 로컬 설정 파일(`~/.oci/config`, `~/.aws/credentials`)을 참조한다.
- **`variables.tf`**:
    - 프로젝트 전반에서 사용되는 입력 변수 정의 (Type, Description, Default).
- **`terraform.tfvars`**:
    - 실제 변수 값 할당.
    - **규칙:** 민감한 값(Password, Secret Key)은 포함하지 않거나, 포함 시 `.gitignore` 필수 등록.
- **`outputs.tf`**:
    - 생성된 리소스의 주요 정보(IP, ID, Endpoint) 출력.
- **`.gitignore`**:
    - Terraform 상태 파일(`*.tfstate`), 변수 파일(`*.tfvars`), 키 파일(`*.pem`, `*.key`) 등 제외 설정.

### 2.2 인프라 리소스 (Infrastructure Layers)
서비스의 성격에 따라 파일을 물리적으로 분리한다:

- **`network.tf` (Network Layer):**
    - VPC/VCN, Subnets, Gateways, Route Tables, Security Groups/Lists.
    - 가장 기초가 되는 뼈대 리소스.
- **`compute.tf` (Compute Layer):**
    - Virtual Machines(Instances), Auto Scaling, SSH Key Association.
    - `network.tf`의 리소스 ID를 참조하여 생성.
- **`storage.tf` (Storage Layer) (Optional):**
    - Block Volume, Object Storage, File Storage.
- **`database.tf` (Data Layer) (Optional):**
    - RDS, Autonomous DB, NoSQL 등.

### 2.3 문서화 및 거버넌스 (Documentation & Governance)
- **`GEMINI_INSTRUCTIONS.md`**:
    - 해당 프로젝트의 작업 규칙, 제약 사항, 워크플로우 정의 (Agent용 헌법).
- **`TERRAFORM_DEV_NOTES.md`**:
    - `tfstate`가 아닌 **작업 변경 이력(History)** 중심의 개발 로그.
- **`ARCHITECTURE.md`**:
    - Mermaid 다이어그램을 활용한 시각적 아키텍처 문서.

## 3. 작업 워크플로우 표준 (Workflow Standards)

1.  **초기화:** `terraform init`
2.  **구현:** 위 파일 구조에 맞춰 리소스 코드를 작성 (변수화 필수).
3.  **검증:** `terraform plan` 실행 결과 확인.
4.  **승인 및 실행:** **사용자의 명시적 승인** 후 `terraform apply`.
5.  **기록:** 작업 완료 후 `TERRAFORM_DEV_NOTES.md` 업데이트 및 `ARCHITECTURE.md` 현행화.

## 4. LLM 프롬프트 예시 (Usage)
새로운 프로젝트 시작 시 다음과 같이 요청한다:
> "이 디렉토리에 있는 `LLM_TERRAFORM_PATTERN.md`를 참고하여, AWS 환경에 VPC와 EC2를 생성하는 Terraform 프로젝트 구조를 잡아줘."
