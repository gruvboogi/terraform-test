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

## [2026-01-30] 인프라 확장, 운영 고도화 및 OKE 트러블슈팅

### 1. 작업 개요
- **목표:** 컴퓨트/데이터베이스 배포, 보안 최적화, OKE 구축 및 비용/운영 관리 체계 수립

### 2. 주요 수행 내역 (컴퓨트 & DB)

#### 2.1 리소스 구축
- **Compute:** ARM 기반 인스턴스 2대 배포 및 `for_each` 기반 동적 수량 제어 구현.
- **Autonomous Database:** `oracle-db.tf` 분리. **ECPU 모델** 및 **Oracle Database 26ai** 버전 적용 성공.

#### 2.2 보안 및 운영 최적화
- **보안 강화:** 코드 내 하드코딩된 OCID 제거 (데이터 소스 및 변수 재활용). `.gitignore`를 통한 기밀 유지.
- **거버넌스:** `GEMINI_INSTRUCTIONS.md`, `LLM_TERRAFORM_PATTERN.md` 수립으로 협업 표준 정의.
- **비용 관리:** Terraform 코드를 통한 인스턴스 상태 제어 및 CLI를 이용한 ADB 중지 처리.

### 3. OKE(Kubernetes) 구축 시도 및 트러블슈팅 이력

#### 3.1 네트워크 복구 및 확장
- OKE 구동을 위해 Private Subnet, NAT Gateway, Service Gateway(SGW) 복구 및 전용 Security List 추가.

#### 3.2 이미지 및 버전 불일치 해결
- **문제:** 클러스터 버전(`v1.31.1`)과 사용 가능한 노드 이미지 버전(`1.31.10`) 불일치로 인한 생성 실패.
- **해결:** `variables.tf`에서 전체 클러스터 버전을 **`v1.31.10`**으로 통합하고, `oke.tf`의 이미지 검색 로직에 정규식(`format("%s-", ...)`)을 적용하여 정확한 패치 버전 매칭 성공.

#### 3.3 노드 등록 타임아웃 이슈 (Pending)
- **현상:** 버전 불일치 해결 후에도 Private Subnet 내 워커 노드가 클러스터에 등록되지 못하는 `register timeout` 발생.
- **분석:** Private Subnet의 아웃바운드 보안 규칙 또는 OKE 컨트롤 플레인과의 통신 경로 문제로 추정. Service Gateway 및 Security List를 보강했으나 해결되지 않음.
- **결정:** 복잡한 네트워크 이슈 해결을 위해 워커 노드를 **Public Subnet**으로 전환하여 배포 시도 결정.

#### 3.4 아키텍처 충돌 및 제약 사항 발견
- **시도:** 위 결정에 따라 워커 노드를 Public Subnet으로 변경하여 생성 시도.
- **오류:** `400-InvalidParameter: The service subnets cannot be used by node pools.` 발생.
- **원인:** OKE는 **로드 밸런서 서브넷(Service Subnet)**과 **노드 풀 서브넷**이 동일한 것을 권장하지 않거나 특정 조건에서 허용하지 않음. Public Subnet을 이미 LB용으로 지정했기 때문에 노드 배치 실패.

#### 3.5 리소스 정리 및 역공학(Reverse Engineering) 전략 수립
- **상태:** Terraform을 통한 반복적인 노드 등록 실패 및 네트워크 제약 발생.
- **조치:** 현재 실패한 OKE 리소스(Cluster, Node Pool)를 `terraform destroy`를 통해 완전히 삭제함 (네트워크 등 기반 리소스는 유지).
- **전략:** OCI 콘솔에서 수동(Manual)으로 클러스터를 성공적으로 생성한 후, 해당 구성을 분석하여 Terraform 코드를 보완하기로 결정.

---

## [2026-02-02] 리소스 정리 (Compute 및 ADB 삭제)

### 1. 작업 개요
- **목표:** 비용 절감 및 환경 재정비를 위해 현재 사용하지 않는 컴퓨트 및 데이터베이스 리소스 제거
- **범위:** Compute 인스턴스 2대 및 Autonomous Database 1대 삭제

### 2. 주요 수행 내역
- **변수 수정:** `variables.tf`에서 `instance_count`를 `0`으로 변경하여 인스턴스 제거 유도
- **설정 비활성화:** `oke.tf` 및 `oracle-db.tf` 파일을 `.bak`으로 변경하여 리소스 관리 대상에서 제외
- **리소스 삭제:** `terraform apply`를 통해 실제 인프라 리소스(Compute, ADB) 삭제 완료
- **현황 유지:** 네트워크(VCN, Subnets, Gateways) 인프라는 향후 재사용을 위해 유지

---

## [2026-02-02] OKE 클러스터 재구축 성공 및 트러블슈팅

### 1. 작업 개요
- **목표:** 수동 생성된 클러스터(`oke_sample`)를 역공학하여 Terraform 기반 OKE 클러스터(`v1.34.1`) 완전 자동 구축
- **환경:** ENHANCED 클러스터, OCI VCN Native CNI 적용, ARM 기반 노드 풀

### 2. 주요 트러블슈팅 및 해결 내역

#### 2.1 이미지 가용성 및 검색 로직 개선
- **문제:** `Oracle Linux 9` 및 특정 패치 버전 기반 이미지 검색 실패.
- **분석:** 리전별 이미지 배포 시점 및 OS 버전(`8.10` 권장) 차이 확인.
- **해결:** 제공된 공식 문서 가이드를 참조하여 **`Oracle Linux 8`** 기반의 OKE 전용 이미지 OCID(`...nwqa`)를 명시적으로 지정하여 해결.

#### 2.2 노드 풀 및 쉐이프(Shape) 호환성
- **오류:** `400-InvalidParameter: Node shape and image are not compatible.`
- **원인:** 초기 지정한 OCID가 GPU 전용 이미지로, `VM.Standard.A1.Flex`(ARM) 쉐이프와 불일치.
- **해결:** ARM 전용 OKE 이미지 OCID로 교체하여 프로비저닝 성공.

#### 2.3 클러스터 애드온(Addons) 충돌 해결
- **오류:** `409-Conflict, addon ... exists`
- **원인:** ENHANCED 클러스터 생성 시 기본 애드온이 자동 설치되어 Terraform 리소스 생성과 충돌.
- **해결:** `oci_containerengine_addon` 리소스에 **`override_existing = true`** 옵션을 추가하여 기존 설치본을 Terraform 관리하에 병합.

#### 2.4 포드(Pod) 네트워크 옵션 동기화
- **오류:** `Invalid NodePoolNetworkOption: NodePool pod network options didn't match cluster pod network options`
- **해결:** 클러스터 레벨의 **`OCI_VCN_IP_NATIVE`** 설정에 맞춰 노드 풀 설정에도 동일한 CNI 타입과 `pod_subnet_ids`를 명시적으로 선언하여 해결.

### 3. 최종 구축 성과
- **클러스터 버전:** `v1.34.1` (성공)
- **네트워크 보안:** OKE 전용 보안 목록(API 엔드포인트용, 노드용) 분리 구축으로 보안 강화.
- **애드온 구성:** CoreDNS, KubeProxy, NvidiaGpuPlugin, OciVcnIpNative 구성 완료.
- **인프라 상태:** 노드 풀 생성 및 노드 프로비저닝 단계 진입 확인.

### 4. 추가 작업: 노드 풀 스케일 아웃 (Scale-Out)
- **요청:** 워커 노드 수량을 1대에서 3대로 증설 요청.
- **조치:** `oke.tf`의 `node_config_details.size`를 `3`으로 수정 후 `terraform apply`.
- **결과:**
    - 노드 2대 추가 생성 완료 (총 3대).
    - Private IP 할당 확인: `192.0.10.31`, `192.0.10.110`, `192.0.10.35`.
    - 모든 노드가 `OCI_VCN_IP_NATIVE` 네트워크 정책 하에 정상적으로 배포됨.

### 5. 추가 작업: 워커 노드 삭제 (Scale-Down to 0)
- **요청:** 비용 절감 및 세션 종료를 위해 생성된 모든 워커 노드 삭제 요청.
- **조치:** `oke.tf`의 `node_config_details.size`를 `0`으로 수정 후 `terraform apply`.
- **결과:** 워커 노드 3대 모두 Terminated 완료. 클러스터 및 네트워크 인프라는 유지하여 재사용 가능성 확보.

---

## [2026-02-04] Network Load Balancer 구축 및 Compute 복구

### 1. 작업 개요
- **목표:** Public Subnet에 Network Load Balancer(NLB)를 구축하고, 삭제되었던 Compute 인스턴스 2대를 복구하여 백엔드로 연결.
- **범위:** NLB(Layer 4), Backend Set, Listener, Security List 추가 및 Compute 인스턴스(ARM) 생성.

### 2. 주요 수행 내역

#### 2.1 인프라 복구 및 확장
- **Compute:** `variables.tf`의 `instance_count`를 `2`로 변경하고 `state`를 `RUNNING`으로 설정하여 `test-1`, `test-2` 인스턴스 재생성.
- **Network:** HTTP(80) 트래픽 허용을 위한 `lb-security-list` 생성 및 Public Subnet에 적용.

#### 2.2 Load Balancer 설정 (`load_balancer.tf`)
- **NLB 생성:** `test-nlb` (Public Facing) 생성 완료.
- **리스너 및 백엔드:** 
    - 80번 포트(TCP) 리스닝 및 백엔드 세트 구성.
    - **헬스 체크 최적화:** 초기 80번 포트에서 **22번 포트(SSH)**로 변경하여 인스턴스 기본 서비스 응답 기반 가용성 체크 적용.
    - `for_each`를 사용하여 생성된 모든 Compute 인스턴스를 백엔드로 자동 등록.

### 3. 결과 확인
- **NLB Public IP:** `168.107.38.86`
- **Compute IPs:** 
    - `test-1`: `168.107.36.142` (Private: `192.0.1.20`)
    - `test-2`: `158.180.83.166` (Private: `192.0.1.123`)
- **상태:** 모든 리소스가 `ACTIVE` 또는 `RUNNING` 상태이며, NLB를 통해 백엔드 인스턴스로 트래픽 분산 준비 완료.

---
*본 노트는 Gemini CLI Agent에 의해 자동 생성 및 업데이트되었습니다.*
