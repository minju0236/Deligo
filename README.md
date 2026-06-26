# 🏍️ Deligo - 사장님을 위한 배달 정산 서비스

## 1. 프로젝트 개요

### 배포 화면
<img width="160" alt="로그인 화면" src="https://github.com/user-attachments/assets/e82ea536-6f0b-4ffe-ac76-064535ef7c03" />
<img width="160" alt="모바일 조회 화면" src="https://github.com/user-attachments/assets/f70eda25-0751-4c87-89e8-1ecc1f3ead0a" />
<img width="160" alt="정산 액션 화면" src="https://github.com/user-attachments/assets/f217f585-a8e0-4f3e-b2ad-abf2f0cee06e" />
<br />
<img width="360" alt="관리자 대시보드" src="https://github.com/user-attachments/assets/5f3c89eb-a811-4897-b124-ac10564415e5" />
<img width="360" alt="관리자 관리 화면" src="https://github.com/user-attachments/assets/12cf2920-3168-4e75-a4fe-7aa0cf3627e4" />

- **수행 주제**: JWT 기반 인증이 포함된 배달 사장님 정산/송금 및 관리자 운영 웹 서비스
- **배포 주소**: https://beijing-chassis-visual-choir.trycloudflare.com
- **사용 기술**
  - Frontend: Next.js, React, JavaScript, Zustand, TanStack Query
  - Backend: Java 21, Spring Boot, Spring Security, Spring Data JPA
  - Database: MariaDB
  - Cache/Session: Redis
  - 인증: JWT (JSON Web Token)
  - 인프라: GCP, Nginx, Cloudflare

---

## 2. 서비스 구성 및 라우팅

Deligo는 배달 사장님이 정산 계좌를 조회하고, 입금/출금/송금 처리를 할 수 있는 모바일 화면과 운영자가 사용자, 계좌, 거래 내역을 관리할 수 있는 관리자 화면으로 구성하였습니다. 백엔드는 `backend-spring-api`의 Spring Boot 서버를 중심으로 REST API를 제공하고, JWT 인증과 Redis 세션 검증을 통해 사용자 데이터를 보호하였습니다.

### 포트 구성
- Nginx                  : 3000
- Next Admin             : 3001
- Next Mobile View       : 3002
- Next Mobile Action     : 3003
- Spring Boot API        : 3004
- MariaDB                : 3306
- Redis                  : 6379
- Cloudflared Tunnel     : http://localhost:3000 공개

### Frontend 구성
- `frontend-mobile-view` → 사장님용 모바일 조회 화면
- `frontend-mobile-action` → 정산 처리, 입금, 출금, 송금 화면
- `frontend-admin` → 운영자용 관리자 대시보드

### Backend 구성
- `AuthController` → 회원가입, 로그인, 내 정보 조회
- `BankController` → 계좌 조회, 거래 내역, 입금/출금/송금
- `AdminController` → 사용자/계좌/거래 운영 관리
- `BankService` → 실제 잔액 변경 및 거래 기록 생성
- `RedisStateService` → 세션, 계좌 캐시, 최근 수취인, 감사 로그 관리

### 인증 관련
- `POST /api/auth/register` → 회원가입 및 기본 정산 계좌 생성
- `POST /api/auth/login` → 로그인 및 JWT 발급
- `GET /api/me` → 로그인 사용자 정보 조회
- `GET /api/health` → API 서버 상태 확인

### 사장님 정산 기능
- `GET /api/bank/account` → 내 정산 계좌 조회
- `GET /api/bank/transactions` → 내 거래 내역 조회
- `GET /api/bank/recent-recipients` → 최근 송금 계좌 조회
- `POST /api/bank/deposit` → 매출 입금 처리
- `POST /api/bank/withdraw` → 정산 출금 처리
- `POST /api/bank/transfer` → 단일 계좌 송금
- `POST /api/bank/multi-transfer` → 여러 계좌 일괄 송금

### 관리자 기능
- `GET /api/admin/dashboard` → 사용자, 계좌, 거래, Redis 감사 로그 조회
- `POST /api/admin/users` → 사용자 생성
- `PATCH /api/admin/users/{userId}/password` → 사용자 비밀번호 변경
- `PATCH /api/admin/users/{userId}/status` → 사용자 상태 변경
- `POST /api/admin/accounts` → 정산 계좌 생성
- `DELETE /api/admin/accounts/{accountId}` → 계좌 해지

---

## 3. 데이터베이스 및 Redis 활용

### 사용 테이블

#### Users (사용자)
- id (PK)
- username (UNIQUE)
- password_hash
- name
- role (USER / ADMIN)
- status (ACTIVE / LOCKED)

#### Accounts (정산 계좌)
- id (PK)
- user_id (FK)
- account_number (UNIQUE)
- balance
- status (ACTIVE / CLOSED)
- version
- created_at

#### Transaction Records (거래 기록)
- id (PK)
- user_id (FK)
- type (DEPOSIT / WITHDRAW / TRANSFER_OUT / TRANSFER_IN)
- amount
- from_account_number
- to_account_number
- memo
- created_at

### Redis 활용
- `auth:session:{sessionId}` → 로그인 세션 저장 및 JWT 세션 검증
- `cache:account:{userId}` → 계좌 조회 결과 단기 캐싱
- `cache:admin:dashboard` → 관리자 대시보드 데이터 캐싱
- `recent:recipients:{userId}` → 최근 송금 계좌 저장
- `audit:logs` → 로그인, 송금, 관리자 작업 감사 로그 저장

### 주요 데이터 흐름

```sql
SELECT * FROM users WHERE username = ?
```

```sql
SELECT * FROM accounts WHERE user_id = ? AND status = 'ACTIVE'
```

```sql
SELECT * FROM transaction_records
WHERE user_id = ?
ORDER BY created_at DESC
LIMIT 30
```

```sql
SELECT * FROM transaction_records
ORDER BY created_at DESC
LIMIT 50
```

---

## 4. 인프라 및 배포 기록

### GCP
- VM 인스턴스 생성 후 Spring Boot API 서버 실행
- MariaDB 설치 및 `deligo_db` 데이터베이스 구성
- Redis 설치 후 세션, 캐시, 감사 로그 저장소로 활용

### Nginx
- 백엔드 API와 3개의 Next.js 프론트엔드 앱을 라우팅
- 관리자 화면, 모바일 조회 화면, 모바일 액션 화면을 각각 다른 포트에서 실행한 뒤 Nginx로 외부 요청 연결

### Cloudflare
- Cloudflare Tunnel 또는 도메인 연결을 통해 외부 접근 가능하도록 구성
- HTTPS 적용 및 배포 URL 연결

### 실행 스크립트
- `scripts/01-install-system-packages.sh` → 서버 패키지 설치
- `scripts/02-setup-mariadb.sh` → MariaDB 구성
- `scripts/03-setup-redis.sh` → Redis 구성
- `scripts/04-build-backend.sh` → Spring Boot 빌드
- `scripts/05-start-backend.sh` → 백엔드 실행
- `scripts/06-install-frontends.sh` → 프론트엔드 의존성 설치
- `scripts/07-start-next-servers.sh` → Next.js 앱 실행
- `scripts/08-setup-nginx.sh` → Nginx 설정
- `scripts/09-start-cloudflared.sh` → Cloudflare Tunnel 실행
- `scripts/10-test-api-flow.sh` → 회원가입부터 송금까지 API 흐름 테스트
- `scripts/11-test-routing.sh` → 라우팅 연결 테스트

---

## 5. 트러블슈팅

### 사례 1: 기존 코드를 파악하는 과정이 어려웠음
- 문제: 처음에는 이미 만들어져 있던 구조를 수정하는 방식으로 진행해서, 어떤 화면이 단순 조회용 `view`이고 어떤 화면이 실제 기능을 실행하는 `action` 화면인지 바로 구분하기 어려웠다.
- 원인: 처음부터 내가 만든 구조가 아니라 기존 코드 흐름을 먼저 이해해야 했고, 프론트가 여러 개로 나뉘어 있어서 역할 파악에 시간이 걸렸다.
- 해결: 각 화면과 api를 확인하면서 `frontend-mobile-view`, `frontend-mobile-action`, `frontend-admin`의 역할을 나눠서 이해했다. view는 읽기 전용 화면, action은 db 수정 로직이 들어간 화면, admin은 관리자 화면이었다.

### 사례 2: 인증되지 않은 상태에서 접근했을 때의 흐름을 늦게 파악함
- 문제: 탭이나 주소로 바로 들어갔을 때 인증되지 않은 사용자는 로그인 유도 화면으로 막히는데, 처음에는 이 흐름을 제대로 확인하지 못했다.
- 원인: 로그인 이후의 화면만 보고 기능을 확인하려고 해서, 인증 전 상태에서 어떤 화면이 나오는지 놓쳤다.
- 해결: 로그인 전/후 상태를 나눠서 확인했고, JWT 토큰이 없을 때는 로그인 화면으로 유도되는 구조를 이해했다.

### 사례 3: IntelliJ 환경이 익숙하지 않음
- 문제: IntelliJ에서 로컬 테스트를 한 뒤 GCP에 올리는 과정에서 환경 설정이 헷갈렸다.
- 원인: IntelliJ에서 Docker를 처음 연결해봤고, 플러그인 설정이나 Ubuntu 환경에서 DB 연결, shell 실행 같은 과정이 익숙하지 않았다.
- 해결: IntelliJ 플러그인 연결, Ubuntu 환경 구성, MariaDB/Redis 연결, shell 스크립트 실행 과정을 직접 해보면서 로컬과 서버 환경의 차이를 이해했다.

### 사례 4: 프론트엔드가 여러 포트로 나뉘어 있어 접근 흐름이 헷갈림
- 문제: 처음에는 관리자 화면, 모바일 조회 화면, 모바일 액션 화면을 각각 다른 포트로 직접 접속해야 하는 줄 알았다.
- 원인: 프론트가 여러 개로 분리되어 있었고, Nginx가 이 요청들을 하나로 묶어주는 역할을 처음에는 잘 이해하지 못했다.
- 해결: Nginx 설정을 통해 하나의 진입점(3000)에서 경로별로 프론트 서버(3001, 3002, 3003)를 연결할 수 있다는 것을 알게 되었다.

---

## 6. 최종 회고

### 배운 점
- Nginx의 로드밸런싱과 라우팅 흐름을 확실히 배운 것 같다.
- 프론트를 여러 개로 나누더라도, Nginx로 하나의 서비스처럼 묶을 수 있다는 점이 가장 크게 와닿았다.
- 처음에는 각각의 포트로 직접 들어가야 한다고 생각했는데, 결국 사용자는 하나의 주소로 접근하고 내부에서 경로에 따라 나뉘는 구조라는 걸 이해했다.
- Redis는 개념만 알고 있었는데, 실제 서비스 로직에서 세션 관리나 캐싱에 어떻게 쓰이는지 알 수 있었다. (ex. redisStateService)
- 특히 어떤 값을 기준으로 캐싱하고, 언제 캐시를 지우는지 흐름을 보는 게 도움이 됐다. (ex. cache:account:{userId})
- 인텔리제이에서 Docker, Ubuntu, DB 연결, shell 실행까지 직접 해보면서 로컬 개발과 배포 환경이 어떻게 이어지는지도 경험했다.

### 아쉬운 점
- 기존 코드를 수정하는 방식이라 처음 구조 파악에 시간이 꽤 걸렸다.
- `view`, `action`, `admin` 화면의 역할을 처음부터 명확히 이해하지 못해서 초반에 헷갈렸다.
- 인증이 안 된 상태에서 접근했을 때 로그인 유도 화면으로 막히는 흐름도 처음에는 제대로 확인하지 못했다.
- 지금은 모바일이면 유저용, 랩탑이면 관리자용처럼 나누었는데, 실제 현업에서는 이런 화면 분리를 어떻게 하는지 궁금했다.
- 관리자 화면도 지금은 단순 로그를 보여주는 정도라서 데이터가 많아졌을 때는 부족할 것 같다고 느꼈다.

### 개선 계획
- 다음에는 백엔드도 여러 서버로 나누어서 로드밸런싱을 해보고 싶다.
- 배달 정산뿐만 아니라 실제 배달 주문까지 가능한 서비스로 확장해보고 싶다.
- 관리자 로그가 많아졌을 때를 대비해서 아카이브나 파티셔닝 같은 방식도 적용해보고 싶다.
- 실제 현업에서는 사용자 화면과 관리자 화면을 어떻게 분리하고 배포하는지 더 알아보고 싶다.
- Redis 캐싱이나 세션 관리도 더 다양한 상황에서 써보면서 익숙해지고 싶다.

---

## 한줄 정리

> 인증 + 정산 계좌 + 송금 처리 + 관리자 운영 기능을 통합한 배달 정산 풀스택 웹 서비스
