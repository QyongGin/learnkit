package com.learnkit.backend.controller;

import com.learnkit.backend.dto.CardDto;
import com.learnkit.backend.service.CardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 카드(단어) 관련 API를 처리하는 컨트롤러
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/api")
public class CardController {

    private final CardService cardService;

    /**
     * 단어장에 새로운 카드를 추가함.
     *
     * @param wordBookId 단어장 ID
     * @param requestDto 카드 생성 정보
     * @return 생성된 카드 정보
     */
    @PostMapping("/wordbooks/{wordBookId}/cards")
    public ResponseEntity<CardDto.Response> createCard(
            @PathVariable Long wordBookId,
            @RequestBody CardDto.CreateRequest requestDto) {
        CardDto.Response response = cardService.createCard(wordBookId, requestDto);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * 특정 단어장의 모든 카드를 조회함.
     *
     * @param wordBookId 단어장 ID
     * @return 카드 목록
     */
    @GetMapping("/wordbooks/{wordBookId}/cards")
    public ResponseEntity<List<CardDto.Response>> getCardsByWordBook(
            @PathVariable Long wordBookId) {
        List<CardDto.Response> cards = cardService.findCardsByWordBookId(wordBookId);
        return ResponseEntity.ok(cards);
    }

    /**
     * 카드 기본 정보를 조회함 (학습용).
     * 질문/답, 다음 복습 시간, 난이도만 포함.
     *
     * @param cardId 카드 ID
     * @return 카드 기본 정보
     */
    @GetMapping("/cards/{cardId}")
    public ResponseEntity<CardDto.Response> getCard(@PathVariable Long cardId) {
        CardDto.Response card = cardService.findCardById(cardId);
        return ResponseEntity.ok(card);
    }

    /**
     * 카드 상세 정보를 조회함 (통계/관리용).
     * 복습 기록, 조회 수, 생성/수정 시간 등 모든 정보 포함.
     *
     * @param cardId 카드 ID
     * @return 카드 상세 정보
     */
    @GetMapping("/cards/{cardId}/detail")
    public ResponseEntity<CardDto.DetailResponse> getCardDetail(@PathVariable Long cardId) {
        CardDto.DetailResponse cardDetail = cardService.findCardDetailById(cardId);
        return ResponseEntity.ok(cardDetail);
    }

    /**
     * 카드 내용을 수정함.
     *
     * @param cardId 카드 ID
     * @param requestDto 수정할 정보
     * @return 수정된 카드 정보
     */
    @PatchMapping("/cards/{cardId}")
    public ResponseEntity<CardDto.Response> updateCard(
            @PathVariable Long cardId,
            @RequestBody CardDto.UpdateRequest requestDto) {
        CardDto.Response updatedCard = cardService.updateCard(cardId, requestDto);
        return ResponseEntity.ok(updatedCard);
    }

    /**
     * 카드를 복습하고 난이도를 선택함.
     * 복습 시간, 조회 수, 다음 복습 시간이 자동으로 업데이트됨.
     *
     * @param cardId 카드 ID
     * @param requestDto 난이도 선택 정보
     * @return 복습 완료된 카드 정보
     */
    @PatchMapping("/cards/{cardId}/review")
    public ResponseEntity<CardDto.Response> reviewCard(
            @PathVariable Long cardId,
            @RequestBody CardDto.ReviewRequest requestDto) {
        CardDto.Response reviewedCard = cardService.reviewCard(cardId, requestDto);
        return ResponseEntity.ok(reviewedCard);
    }

    /**
     * 카드를 삭제함.
     *
     * @param cardId 카드 ID
     * @return 삭제 완료 응답
     */
    @DeleteMapping("/cards/{cardId}")
    public ResponseEntity<Void> deleteCard(@PathVariable Long cardId) {
        cardService.deleteCard(cardId);
        return ResponseEntity.noContent().build();
    }

    /**
     * 사용자의 모든 카드에 대한 난이도별 통계를 조회함.
     *
     * @param userId 사용자 ID
     * @return 난이도별 카드 통계
     */
    @GetMapping("/users/{userId}/cards/statistics")
    public ResponseEntity<CardDto.StatisticsResponse> getCardStatistics(@PathVariable Long userId) {
        CardDto.StatisticsResponse statistics = cardService.getCardStatisticsByUserId(userId);
        return ResponseEntity.ok(statistics);
    }

    /**
     * 특정 단어장의 카드에 대한 난이도별 통계를 조회함.
     * 단어장 목록 UI에서 각 단어장의 학습 진행 상황을 표시할 때 사용.
     *
     * @param wordBookId 단어장 ID
     * @return 난이도별 카드 통계
     */
    @GetMapping("/wordbooks/{wordBookId}/cards/statistics")
    public ResponseEntity<CardDto.StatisticsResponse> getWordBookCardStatistics(@PathVariable Long wordBookId) {
        CardDto.StatisticsResponse statistics = cardService.getCardStatisticsByWordBookId(wordBookId);
        return ResponseEntity.ok(statistics);
    }
}