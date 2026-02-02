# OCI Infrastructure Architecture

이 문서는 Terraform을 통해 구축된 현재(`2026-01-30` 기준) OCI 인프라 아키텍처를 시각화한 것입니다.

## Infrastructure Diagram

```mermaid
graph TD
    %% Define Styles
    classDef compartment fill:#f9f9f9,stroke:#333,stroke-width:2px;
    classDef vcn fill:#e6f3ff,stroke:#0066cc,stroke-width:2px;
    classDef subnet fill:#e6ffe6,stroke:#009933,stroke-width:2px;
    classDef compute fill:#ffcc00,stroke:#cc9900,stroke-width:2px;
    classDef db fill:#00d4ff,stroke:#00a3cc,stroke-width:2px;
    classDef gateway fill:#ff9999,stroke:#cc3300,stroke-width:2px;
    classDef internet fill:#ffffff,stroke:#000000,stroke-width:2px,stroke-dasharray: 5 5;
    classDef oke fill:#326ce5,stroke:#2856ad,stroke-width:2px,color:#fff;

    Internet((Internet)):::internet

    subgraph Region ["Region: ap-chuncheon-1"]
        subgraph Comp ["Compartment: terraform-test"]
            
            subgraph VCN ["VCN: terraform-test-vcn (192.0.0.0/16)"]
                
                IGW[Internet Gateway: test-igw]:::gateway
                NAT[NAT Gateway: test-nat]:::gateway
                SGW[Service Gateway: test-sgw]:::gateway
                
                subgraph AD1 ["Availability Domain 1"]
                    
                    subgraph PubSub ["Public Subnet (192.0.1.0/24)"]
                        direction TB
                        Inst1[("Compute: test-1<br/>(A1.Flex)")]:::compute
                        Inst2[("Compute: test-2<br/>(A1.Flex)")]:::compute
                    end

                    subgraph PrivSub ["Private Subnet (192.0.10.0/24)"]
                        direction TB
                        Node1[("OKE Worker Node<br/>(Target State)")]:::compute
                    end

                    ADB[("Autonomous DB<br/>(26ai, ECPU)")]:::db
                end
                
                OKE_CP["OKE Control Plane<br/>(API Endpoint)"]:::oke
            end
        end
    end

    %% Network Flows
    Internet <==> IGW
    IGW --- PubSub
    NAT --- PrivSub
    SGW --- PrivSub
    
    %% Connections
    PubSub --- Inst1
    PubSub --- Inst2
    PrivSub --- Node1
    PubSub --- OKE_CP
    Comp --- ADB

    %% Styling
    class Comp compartment
    class VCN vcn
    class PubSub subnet
    class PrivSub subnet
    class AD1 compartment
```

## Resource Details

| Resource Type | Name | CIDR / Spec | Description |
| :--- | :--- | :--- | :--- |
| **Region** | ap-chuncheon-1 | - | 춘천 리전 |
| **VCN** | terraform-test-vcn | `192.0.0.0/16` | 메인 가상 네트워크 |
| **Subnet (Public)** | public-subnet | `192.0.1.0/24` | 외부 접속용 서브넷 (Compute, OKE API) |
| **Subnet (Private)** | private-subnet | `192.0.10.0/24` | 보안 서브넷 (OKE Worker Nodes 배치용) |
| **Gateways** | IGW / NAT / SGW | - | 인터넷 및 OCI 서비스 통신용 게이트웨이 세트 |
| **Compute** | test-1 / test-2 | VM.Standard.A1.Flex | Oracle Linux 9 (ARM), 현재 STOPPED 상태 |
| **Database** | test-autonomous-db | 26ai (ECPU) | Autonomous DB, 2 ECPUs, 현재 STOPPED 상태 |
| **OKE (Target)** | terraform-oke-cluster | v1.31.10 | 쿠버네티스 클러스터 (수동 생성 예정) |
