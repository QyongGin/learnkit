# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LearnKit은 학습 일정 관리 애플리케이션의 Spring Boot 백엔드 프로젝트입니다.

**Tech Stack:**
- Java 21
- Spring Boot 3.5.6
- Spring Data JPA
- Spring Security
- MySQL
- Lombok

## Build & Run Commands

**Build the project:**
```bash
./gradlew build
```

**Run the application:**
```bash
./gradlew bootRun
```

**Run tests:**
```bash
./gradlew test
```

**Run a single test class:**
```bash
./gradlew test --tests com.learnkit.backend.ClassName
```

**Clean build:**
```bash
./gradlew clean build
```

## Database Configuration

MySQL 데이터베이스가 필요합니다:
- Database: `learnket_db`
- Username: `learnkit_user`
- Connection: `localhost:3306`
- Credentials는 `src/main/resources/application.properties`에 설정되어 있습니다.

## Architecture

### Domain-Driven Layer Structure

프로젝트는 계층형 아키텍처를 따릅니다:

```
controller → service → repository → domain
     ↓          ↓          ↓           ↓
   HTTP     비즈니스    데이터       엔티티
   요청/응답   로직      접근        모델
```

**핵심 원칙:**
- **DTO 분리**: 컨트롤러는 DTO를 사용하고, 서비스 계층에서 Entity와 DTO 간 변환을 담당합니다.
- **Entity 보호**: Entity는 `domain` 패키지에 격리되어 있으며, 비즈니스 로직을 포함합니다.
- **Service 책임**: Service는 DTO에서 데이터를 추출하여 Entity의 메서드에 순수 데이터만 전달합니다.

### JPA Auditing Pattern

`BaseTimeEntity`를 상속받아 자동 타임스탬프를 사용합니다:
- `@EnableJpaAuditing`이 메인 애플리케이션에 활성화되어 있습니다.
- `createdAt`, `updatedAt` 필드가 자동으로 관리됩니다.
- 새 Entity를 만들 때는 `extends BaseTimeEntity`를 추가하세요.

### Fetch Strategy

**LAZY Loading 사용:**
- 연관관계(`@ManyToOne`, `@OneToMany`)는 기본적으로 `FetchType.LAZY`를 사용합니다.
- 예: `Schedule`의 `User` 참조는 실제로 접근할 때만 로드됩니다.
- 성능 최적화를 위해 N+1 문제를 피하려면 필요 시 `@EntityGraph` 또는 `JOIN FETCH`를 사용하세요.

### Exception Handling Pattern

**전역 예외 처리:**
- `GlobalExceptionHandler`에 `@RestControllerAdvice`를 사용합니다.
- 커스텀 예외는 `exception/custom/` 패키지에 정의합니다.
- 모든 예외는 `ErrorResponse` 형태로 일관되게 응답됩니다.

**새 예외 추가 시:**
1. `exception/custom/` 패키지에 커스텀 예외 클래스 생성
2. `GlobalExceptionHandler`에 `@ExceptionHandler` 메서드 추가
3. 적절한 HTTP 상태 코드와 함께 `ErrorResponse` 반환

### DTO Naming Convention

이 프로젝트는 중첩된 정적 클래스를 사용하는 DTO 패턴을 따릅니다:

```java
public class ScheduleDto {
    public static class CreateRequest { ... }
    public static class UpdateRequest { ... }
    public static class Response { ... }
}
```

**새 엔티티에 대한 DTO 작성 시:**
- 단일 `XxxDto` 클래스 내에 정적 내부 클래스로 요청/응답 DTO를 그룹화하세요.
- `CreateRequest`: POST 요청용
- `UpdateRequest`: PATCH/PUT 요청용
- `Response`: 모든 응답용
- 각 DTO에 `toEntity()` 또는 생성자를 통한 변환 메서드를 포함하세요.

### Dirty Checking for Updates

**서비스 계층에서 `@Transactional` 사용:**
- Entity의 변경사항은 트랜잭션 종료 시 자동으로 DB에 반영됩니다.
- 업데이트 시 명시적인 `repository.save()` 호출이 필요 없습니다.
- Entity 내에 `update()` 메서드를 정의하여 변경 가능한 필드만 수정합니다.
- PATCH 요청 지원을 위해 null 체크를 통해 제공된 필드만 업데이트합니다.

## Code Style Guidelines

**Lombok 사용:**
- Entity와 DTO에 `@Getter`, `@NoArgsConstructor` 사용
- Controller/Service에 `@RequiredArgsConstructor` 사용 (생성자 주입)
- `@Setter` 사용 지양 (불변성 유지)

**한국어 주석:**
- 이 프로젝트는 학습 목적으로 한국어 주석을 포함합니다.
- 복잡한 로직이나 JPA 동작 설명 시 한국어 주석을 추가하세요.
- 주석은 "왜"를 설명하며, "무엇"은 코드로 명확히 표현하세요.

## Claude Code Workflow (토큰 최적화)

**최우선 원칙: 모든 작업에서 토큰 사용을 최소화하는 방법을 선택합니다.**

프로젝트 작업 시 토큰 비용을 최적화하기 위해 다음 규칙을 따릅니다:

### 파일 작업 규칙

**1. 새 파일 생성:**
- Write 도구를 사용하지 않고, **주석 포함한 전체 코드만 제공**합니다.
- 사용자가 직접 파일을 생성하고 코드를 작성합니다.
- 이 방식이 도구 메타데이터 overhead를 줄여 ~27% 토큰 절약.

**2. 기존 파일 부분 수정:**
- **Edit 도구를 직접 사용**하여 수정합니다.
- 변경되는 부분만 전송하므로 전체 코드 출력보다 훨씬 효율적입니다.
- Read → Edit → 간단한 설명 순서로 진행.

**3. 기존 파일 전체 교체:**
- 파일 구조가 완전히 바뀌거나 대부분의 내용이 변경되는 경우
- **Write 도구를 사용하여 덮어쓰기**합니다.
- 전체 코드를 출력하는 것보다 Write 도구가 더 효율적입니다.

### 응답 작성 원칙

- 불필요한 설명이나 예시는 최소화합니다.
- 코드 출력 시 주석은 포함하되, 과도한 설명은 피합니다.
- 여러 파일 작업 시, 가능한 한 도구 사용을 우선합니다.
- 토큰 사용량이 의심되면 항상 더 효율적인 방법을 선택합니다.

**예시 형식 (새 파일):**
```
📁 새 파일: src/main/java/com/learnkit/backend/service/NewService.java

다음 내용으로 파일을 만들어주세요:

```java
package com.learnkit.backend.service;

/**
 * 새로운 서비스 설명
 */
@Service
@RequiredArgsConstructor
public class NewService {
    // 코드 내용...
}
```

## Claude 답변 스타일 가이드

**핵심 원칙:**
- 간결하게 답변 (불필요한 예시/설명 최소화)
- 코드는 명시적으로 요청받았을 때만 제공
- 핵심만 전달, 토큰 효율적 사용
