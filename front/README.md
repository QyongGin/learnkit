# LearnKit

학습을 도와주는 스마트 학습 관리 앱입니다.

## 주요 기능

### 홈 화면
- **날짜 표시**: 현재 날짜를 한글로 표시
- **드래그 가능한 캘린더**: 날짜 헤더를 탭하거나 드래그하여 캘린더 펼치기/접기
- **스케줄 관리**: 
  - 캘린더에서 날짜 길게 누르기로 일정 추가
  - 플로팅 액션 버튼(+)으로 빠른 일정 추가
  - 일정 탭하여 수정/삭제
  - 일정 타입별 색상 구분 (할 일/이벤트/공부/미팅)
- **타이머**: 이번 주 학습 시간 추적
- **단어장**: 학습한 단어 통계 (쉬움/보통/어려움)
- **오늘의 목표**: 원형 진행도와 함께 목표 달성률 표시
- **진행 상황**: 선형 진행 바로 전체 진행도 표시
- **주간 정산**: 주간 목표 달성률과 뽀모도로 카운트

## 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점
├── models/
│   ├── home_data.dart          # 홈 화면 데이터 모델
│   └── schedule.dart           # 스케줄 데이터 모델
├── services/
│   ├── api_service.dart        # API 통신 서비스
│   └── auth_service.dart       # 사용자 인증 서비스
├── screens/
│   ├── home_screen.dart        # 홈 화면
│   └── schedule_form_screen.dart # 일정 추가/수정 화면
└── widgets/
    ├── section_card.dart       # 재사용 가능한 위젯들
    └── calendar_widget.dart    # 캘린더 위젯
```

## 기술 스택

- **Flutter**: 크로스 플랫폼 UI 프레임워크
- **http**: REST API 통신
- **intl**: 날짜/시간 국제화
- **table_calendar**: 캘린더 위젯
- **shared_preferences**: 로컬 데이터 저장
- **fl_chart**: 차트 및 그래프 (향후 사용)

## 시작하기

### 패키지 설치
```bash
flutter pub get
```

### 앱 실행
```bash
flutter run
```

## 사용자 인증

**회원가입 기능 없이 userId=1로 고정**
- 앱 시작 시 자동으로 userId=1로 로그인됨
- `AuthService`가 로컬에 로그인 정보 저장
- 모든 API 요청에 userId=1 사용

### 디버깅용 메서드
```dart
// 로그아웃 (테스트용)
await authService.logout();

// 초기화 및 재로그인
await authService.reset();
```

## API 연동

현재는 더미 데이터를 사용하고 있습니다. 실제 서버와 연동하려면:

1. `lib/services/api_service.dart` 파일에서 `baseUrl`을 실제 서버 URL로 변경
2. 모든 API는 userId=1을 사용합니다

### 백엔드 API 엔드포인트

| 기능 | 메서드 | 엔드포인트 | 설명 |
|------|--------|-----------|------|
| 홈 데이터 조회 | GET | `/api/home` | 홈 화면 데이터 |
| 스케줄 목록 조회 | GET | `/api/users/1/schedules` | 사용자의 모든 스케줄 |
| 스케줄 상세 조회 | GET | `/api/schedules/{scheduleId}` | 특정 스케줄 상세 |
| 스케줄 생성 | POST | `/api/users/1/schedules` | 새 스케줄 생성 |
| 스케줄 수정 | PATCH | `/api/schedules/{scheduleId}` | 스케줄 수정 |
| 스케줄 삭제 | DELETE | `/api/schedules/{scheduleId}` | 스케줄 삭제 |

### 홈 데이터 JSON 형식
```json
{
  "date": "2025년 9월 21일 일요일",
  "timerInfo": {
    "hours": 7,
    "minutes": 15
  },
  "wordInfo": {
    "learned": 12,
    "reviewed": 30,
    "difficult": 3
  },
  "goalProgress": {
    "completed": 3,
    "total": 5
  },
  "progressInfo": {
    "percentage": 80
  },
  "weeklyStats": {
    "goalIncrease": 60,
    "pomototoCount": 32
  }
}
```

### 스케줄 JSON 형식

#### 생성 요청 (POST)
```json
{
  "title": "Flutter 공부",
  "description": "State Management 학습",
  "date": "2025-10-06T00:00:00.000Z",
  "startTime": "2025-10-06T14:00:00.000Z",
  "endTime": "2025-10-06T16:00:00.000Z",
  "type": "study"
}
```

#### 수정 요청 (PATCH)
```json
{
  "title": "Flutter 공부 (수정)",
  "isCompleted": true
}
```

#### 응답 형식
```json
{
  "id": "1",
  "title": "Flutter 공부",
  "description": "State Management 학습",
  "date": "2025-10-06T00:00:00.000Z",
  "startTime": "2025-10-06T14:00:00.000Z",
  "endTime": "2025-10-06T16:00:00.000Z",
  "isCompleted": false,
  "type": "study",
  "color": "#FF9800"
}
```

## UI/UX 특징

- ✨ 깔끔한 카드 기반 디자인
- 🎨 부드러운 그림자와 둥근 모서리
- 🔄 Pull-to-refresh로 데이터 새로고침
- 📱 Material Design 3 적용
- 🎯 직관적인 진행도 시각화

## 향후 개발 계획

- [ ] 각 섹션 상세 화면 구현
- [ ] 실시간 타이머 기능
- [ ] 단어장 관리 기능
- [ ] 목표 설정 및 관리
- [ ] 통계 및 분석 차트
- [ ] 푸시 알림
- [ ] 사용자 인증

## 라이선스

이 프로젝트는 개인 프로젝트입니다.
