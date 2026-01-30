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
    classDef gateway fill:#ff9999,stroke:#cc3300,stroke-width:2px;
    classDef internet fill:#ffffff,stroke:#000000,stroke-width:2px,stroke-dasharray: 5 5;

    Internet((Internet)):::internet

    subgraph Region ["Region: ap-chuncheon-1"]
        subgraph Comp ["Compartment: terraform-test"]
            
            subgraph VCN ["VCN: terraform-test-vcn (192.0.0.0/16)"]
                
                IGW[Internet Gateway: test-igw]:::gateway
                
                subgraph AD1 ["Availability Domain 1"]
                    
                    subgraph PubSub ["Public Subnet (192.0.1.0/24)"]
                        direction TB
                        
                        Inst1[("Compute: test-1<br/>(VM.Standard.A1.Flex)<br/>1 OCPU, 6GB RAM")]:::compute
                        Inst2[("Compute: test-2<br/>(VM.Standard.A1.Flex)<br/>1 OCPU, 6GB RAM")]:::compute
                    end
                end
                
                RT[Route Table: public-rt]
            end
        end
    end

    %% Network Flows
    Internet <==> IGW
    IGW <==> RT
    RT ==> PubSub
    
    %% Implicit connections within subnet
    PubSub --- Inst1
    PubSub --- Inst2

    %% Styling
    class Comp compartment
    class VCN vcn
    class PubSub subnet
    class AD1 compartment
```

## Resource Details

| Resource Type | Name | CIDR / Spec | Description |
| :--- | :--- | :--- | :--- |
| **Region** | ap-chuncheon-1 | - | 춘천 리전 |
| **VCN** | terraform-test-vcn | `192.0.0.0/16` | 메인 가상 네트워크 |
| **Subnet** | public-subnet | `192.0.1.0/24` | 외부 접속이 가능한 Public Subnet |
| **Gateway** | test-igw | - | Internet Gateway (인터넷 통신용) |
| **Compute** | test-1 | VM.Standard.A1.Flex | Oracle Linux 9 (ARM), 1 OCPU, 6GB RAM |
| **Compute** | test-2 | VM.Standard.A1.Flex | Oracle Linux 9 (ARM), 1 OCPU, 6GB RAM |
