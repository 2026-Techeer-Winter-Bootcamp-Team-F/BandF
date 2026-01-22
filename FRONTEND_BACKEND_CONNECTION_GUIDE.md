# Frontend-Backend & Codef API 연동 가이드 (최신 업데이트 완료)

이 문서는 **2026년 1월 22일** 기준, Frontend(Flutter)와 Backend(Django)의 **Codef API 간편인증 연동** 구현 및 **최근 발생한 오류 수정 내역**을 정리한 통합 문서입니다.

---

## 1. 최근 수정 내역 (Hotfixes)

### A. Backend (`codef/views.py`) - 문법 오류 수정
*   **증상**: `docker-compose up` 실행 시 `SyntaxError: invalid syntax` 발생.
*   **원인**: `if-elif-else` 구문에서 `else:` 블록이 중복으로 작성되어 파싱 에러 발생.
*   **조치**: 중복된 `else` 블록 라인을 제거하고, 정상적인 에러 로깅(`logger.error`) 흐름으로 복구 완료.

### B. Database (`docker-compose.yml`) - 연결 오류 수정
*   **증상**: Django 시작 시 `OperationalError: (2005, "Unknown server host 'mysqldb'")` 반복 발생.
*   **원인**: `mysqldb` 컨테이너가 비정상 종료(Exited)되어 백엔드가 DB 호스트를 찾지 못함.
*   **조치**: `docker-compose restart` 명령어로 DB 컨테이너 재기동 및 연결 회복.

### C. Frontend (`connect_bank_page.dart`) - UX/디버깅 강화
*   **증상**: [연결하기] 버튼 클릭 시 반응 없음(Silent Failure).
*   **원인**: 폼 검증(Validator) 실패 시 에러 메시지가 표시되지 않아 사용자는 멈춘 것으로 오인.
*   **조치**:
    1.  `autovalidateMode`를 `onUserInteraction`으로 설정하여 입력 즉시 에러 표시.
    2.  `print` 디버그 로그(`=== Connect Button Pressed ===`) 추가로 클릭 이벤트 감지 확인.
    3.  `_formKey.currentState!.validate()` 결과를 변수로 받아 명시적으로 검증 실패 로그 출력.

---

## 2. 시스템 아키텍처 및 인증 흐름

### 간편인증 프로세스 (2-Way Authentication)
KB국민카드 등 주요 금융사는 ID/PW 스크래핑을 차단하므로 **간편인증(Simple Auth)** 방식을 사용해야 합니다.

1.  **사용자 입력 (Frontend)**
    *   **필수 정보**: 이름, 휴대폰번호, 통신사(SKT/KT/LG/알뜰폰), 생년월일(7자리)
    *   **인증 수단**: 카카오톡, 토스, PASS, 페이코 등 선택.
2.  **1차 요청 (Frontend → Backend → Codef)**
    *   `loginType: '5'` (간편인증)
    *   `loginTypeLevel`: 앱 구분 코드 (예: '1' 카카오톡, '4' 토스)
3.  **인증 대기 (Codef CF-03002)**
    *   Codef가 `CF-03002` 응답을 주면, Backend는 이를 `HTTP 202 Accepted`로 프론트엔드에 전달.
    *   응답 데이터에 `two_way_info` 포함.
4.  **사용자 승인 (App Action)**
    *   사용자 휴대폰으로 인증 요청 알림 도착 → 승인 완료.
5.  **2차 요청 (Frontend → Backend → Codef)**
    *   사용자가 앱에서 [인증 완료] 버튼 클릭.
    *   1차 요청의 `two_way_info`를 그대로 Backend에 전송하여 세션 이어가기.
6.  **최종 완료**
    *   Connected ID 발급 성공 (`HTTP 201 Created`).

---

## 3. 파일별 상세 구현 내역

### Backend (`Backend-main/`)

#### `codef/service.py`
*   **API URL 변경**: `sandbox.codef.io` 대신 `api.codef.io` 사용 (데모 계정도 정식 URL 사용 필요).
*   **간편인증 파라미터**: `user_name`, `phone_no`, `identity`(주민앞7자리), `telecom` 처리 로직 추가.
*   **2FA 처리**: Codef 결과가 `CF-03002`일 경우 `is_2fa: True` 플래그와 `two_way_info`를 반환하도록 구조화.

#### `codef/views.py`
*   **상태 코드 분기**:
    *   성공 (`CF-00000`): `HTTP 201 Created`
    *   추가 인증 필요 (`CF-03002`): `HTTP 202 Accepted`
    *   실패 (`CF-00017` 등): `HTTP 400 Bad Request`

### Frontend (`Frontend/lib/`)

#### `screens/settings/connect_bank_page.dart`
*   **Form 필드**:
    *   ID/PW 입력 모드와 간편인증 입력 모드를 라디오 버튼으로 전환.
    *   통신사 선택 및 인증 앱 선택(`DropdownButtonFormField`) 구현.
*   **에러 핸들링**: `result['is_2fa']` 체크를 통해 UI 상태를 "대기중"으로 변경하고 [인증 완료] 버튼 활성화.

#### `services/api_service.dart`
*   **JSON 에러 방어**: Nginx Gateway Error(502) 등으로 인해 HTML이 반환될 경우, `jsonDecode` 에러가 나지 않도록 `try-catch` 및 문자열 체크 로직 추가.
*   **파라미터 확장**: `createConnectedId` 함수가 `twoWayInfo`, `additionalInfo`(Provider) 등을 받을 수 있도록 수정.

---

## 4. 문제 해결 (Troubleshooting) 자주 묻는 질문

### Q. 서버 에러 (502/500) 또는 DB 연결 오류
*   **증상**: `OperationalError (2005, 'mysqldb')`
*   **해결**: DB 컨테이너가 꺼져있는 상태입니다.
    ```bash
    cd Backend-main
    docker-compose up -d
    ```

### Q. [연결하기] 버튼 무반응
*   **증상**: 버튼을 눌러도 로딩이 돌지 않음.
*   **해결**: 터미널 로그 확인. `Validation failed`가 뜬다면 입력값이 부족한 것입니다.
    *   **주민번호**: 반드시 **7자리** (생년월일6자리 + 성별코드1자리)여야 합니다. (예: `9901011`)
    *   **휴대폰**: 하이픈 없이 숫자만 입력 (예: `01012345678`)

### Q. "Token is for sandbox" (CF-00017)
*   **해결**: Codef API 키는 데모용이지만, URL은 운영용(`https://api.codef.io`)을 바라봐야 합니다. `.env` 파일과 `service.py`의 상수를 확인하세요.

---

## 5. 필수 실행 명령어

**코드가 수정되었으므로 반드시 아래 순서로 재시작하세요.**

```bash
# 1. 백엔드 재시작 (Views.py 수정 반영 확인)
cd Backend-main
docker-compose restart backend

# 2. 로그 확인 (에러 없는지 체크)
docker logs backend --tail 20

# 3. 프론트엔드 실행
cd ../Frontend
flutter run
```
