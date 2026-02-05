# OCI Infrastructure Architecture

이 문서는 Terraform을 통해 구축된 현재(`2026-02-05` 기준) OCI 인프라 아키텍처를 시각화한 것입니다.

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
    classDef lb fill:#99ccff,stroke:#0066cc,stroke-width:2px;
    classDef reserve fill:#f9f,stroke:#333,stroke-width:2px;

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
                        NLB["Network Load Balancer<br/>(test-nlb)"]:::lb
                        Inst1[("Compute: test-1<br/>(STOPPED)")]:::compute
                        Inst2[("Compute: test-2<br/>(STOPPED)")]:::compute
                    end

                    subgraph PrivSub ["Private Subnet (192.0.10.0/24)"]
                        direction TB
                        NodeEmpty["OKE Worker Nodes<br/>(Current: 0)"]:::compute
                    end

                    ADB_ST["Autonomous DB<br/>(DELETED)"]:::db
                    
                    CapRes["Capacity Reservation<br/>(ARM x 2)"]:::reserve
                end
                
                OKE_CP["OKE Control Plane<br/>(v1.34.1)"]:::oke
            end
        end
    end

    %% Network Flows
    Internet <==> IGW
    IGW --- NLB
    NLB --- Inst1
    NLB --- Inst2
    NAT --- PrivSub
    SGW --- PrivSub
    
    %% Connections
    PubSub --- OKE_CP

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
| **Subnet (Public)** | public-subnet | `192.0.1.0/24` | 외부 접속용 (NLB, Compute, OKE API) |
| **Subnet (Private)** | private-subnet | `192.0.10.0/24` | 보안 서브넷 (OKE Worker Nodes용) |
| **Network LB** | test-nlb | Layer 4 (TCP) | **Public IP: 168.107.38.86**, 포트 80 리스닝 |
| **Compute** | test-1 / test-2 | VM.Standard.A1.Flex | ARM (STOPPED), 현재 용량 예약 없음 |
| **Capacity Reserve**| test-arm-capacity-reservation | ARM (1 OCPU, 6GB) x 2 | **신규 생성**, ARM 인스턴스 용량 선점용 |
| **OKE** | terraform-oke-cluster | v1.34.1 | 클러스터 활성 상태, 워커 노드 0대 |