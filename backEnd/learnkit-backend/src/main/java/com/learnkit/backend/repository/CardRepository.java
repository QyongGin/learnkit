package com.learnkit.backend.repository;

import com.learnkit.backend.domain.Card;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Card 엔티티의 데이터베이스 접근을 담당하는 Repository
 */
@Repository
public interface CardRepository extends JpaRepository<Card, Long> {

    // JpaRepository: save, findById, findAll, deleteById 기본 메소드 제공

    /**
     * 특정 단어장에 속한 모든 카드를 조회
     *
     * @param wordBookId 단어장 ID
     * @return 해당 단어장의 카드 목록
     */
    List<Card> findByWordBookId(Long wordBookId);

    /**
     * 특정 단어장의 총 카드 개수 조회
     *
     * @param wordBookId 단어장 ID
     * @return 카드 개수
     */
    long countByWordBookId(Long wordBookId);

    /**
     * 특정 사용자의 카드를 난이도별로 집계 (복습한 카드만)
     *
     * @param userId 사용자 ID
     * @param difficulty 난이도
     * @return 해당 난이도의 카드 개수
     */
    // count - 집계 함수 사용 By - WHERE 절 시작 WordBook - 연관관계 조인, User - 연관관계 조인 Difficulty - 직접 필드 접근
    long countByWordBookUserIdAndDifficulty(Long userId, Card.Difficulty difficulty);

    /**
     * 특정 단어장의 카드를 난이도별로 집계 (복습한 카드만)
     *
     * @param wordBookId 단어장 ID
     * @param difficulty 난이도
     * @return 해당 난이도의 카드 개수
     */
    // count - 집계 함수 사용 By - WHERE 절 시작 WordBookId - 단어장 ID 직접 접근 And - 조건 연결 Difficulty - 직접 필드 접근
    long countByWordBookIdAndDifficulty(Long wordBookId, Card.Difficulty difficulty);

    /**
     * 특정 단어장에서 reviewPriority가 가장 작은 카드를 조회함 (학습 세션용).
     * 우선순위를 오름차순 정렬하여 첫 번째 카드를 반환.
     *
     * @param wordBookId 단어장 ID
     * @return reviewPriority가 가장 작은 카드 (Optional)
     */
    // findFirst - 첫 번째 결과만 가져옴 By - WHERE 절 시작 WordBookId - 단어장 ID 조건 OrderBy - 정렬 ReviewPriority - 정렬 기준 필드 Asc - 오름차순
    java.util.Optional<Card> findFirstByWordBookIdOrderByReviewPriorityAsc(Long wordBookId);

    /**
     * 특정 사용자의 모든 카드 조회 (주간 통계용)
     *
     * @param userId 사용자 ID
     * @return 사용자의 모든 카드 목록
     */
    List<Card> findByWordBookUserId(Long userId);
}