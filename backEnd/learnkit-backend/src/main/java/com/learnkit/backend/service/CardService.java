package com.learnkit.backend.service;

import com.learnkit.backend.domain.Card;
import com.learnkit.backend.domain.WordBook;
import com.learnkit.backend.dto.CardDto;
import com.learnkit.backend.exception.custom.CardNotFoundException;
import com.learnkit.backend.exception.custom.WordBookNotFoundException;
import com.learnkit.backend.repository.CardRepository;
import com.learnkit.backend.repository.WordBookRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class CardService {

    private final CardRepository cardRepository;
    private final WordBookRepository wordBookRepository;

    /**
     * 단어장에 새로운 카드를 추가함.
     *
     * @param wordBookId 단어장 ID
     * @param requestDto 카드 생성 정보
     * @return 생성된 카드 정보
     * @throws WordBookNotFoundException 단어장을 찾을 수 없는 경우
     */
    public CardDto.Response createCard(Long wordBookId, CardDto.CreateRequest requestDto) {
        WordBook wordBook = wordBookRepository.findById(wordBookId)
                .orElseThrow(() -> new WordBookNotFoundException(wordBookId));

        Card card = requestDto.toEntity();
        card.setWordBook(wordBook);

        Card savedCard = cardRepository.save(card);
        return new CardDto.Response(savedCard);
    }

    /**
     * 특정 단어장의 모든 카드를 조회함.
     *
     * @param wordBookId 단어장 ID
     * @return 카드 목록
     */
    public List<CardDto.Response> findCardsByWordBookId(Long wordBookId) {
        List<Card> cards = cardRepository.findByWordBookId(wordBookId);
        return cards.stream()
                .map(CardDto.Response::new)
                .toList();
    }

    /**
     * 카드 기본 정보를 조회함 (학습용).
     * 질문/답, 다음 복습 시간, 난이도만 포함.
     *
     * @param cardId 카드 ID
     * @return 카드 기본 정보
     * @throws CardNotFoundException 카드를 찾을 수 없는 경우
     */
    public CardDto.Response findCardById(Long cardId) {
        Card card = cardRepository.findById(cardId)
                .orElseThrow(() -> new CardNotFoundException(cardId));
        return new CardDto.Response(card);
    }

    /**
     * 카드 상세 정보를 조회함 (통계/관리용).
     * 복습 기록, 조회 수, 생성/수정 시간 등 모든 정보 포함.
     *
     * @param cardId 카드 ID
     * @return 카드 상세 정보
     * @throws CardNotFoundException 카드를 찾을 수 없는 경우
     */
    public CardDto.DetailResponse findCardDetailById(Long cardId) {
        Card card = cardRepository.findById(cardId)
                .orElseThrow(() -> new CardNotFoundException(cardId));
        return new CardDto.DetailResponse(card);
    }

    /**
     * 카드 내용을 수정함.
     *
     * @param cardId 카드 ID
     * @param requestDto 수정할 정보
     * @return 수정된 카드 정보
     * @throws CardNotFoundException 카드를 찾을 수 없는 경우
     */
    public CardDto.Response updateCard(Long cardId, CardDto.UpdateRequest requestDto) {
        Card card = cardRepository.findById(cardId)
                .orElseThrow(() -> new CardNotFoundException(cardId));

        card.update(
                requestDto.getFrontText(),
                requestDto.getBackText()
        );
        return new CardDto.Response(card);
    }

    /**
     * 카드를 복습하고 난이도를 선택함.
     * 복습 시간, 조회 수, 다음 복습 시간이 자동으로 업데이트됨.
     *
     * @param cardId 카드 ID
     * @param requestDto 난이도 선택 정보
     * @return 복습 완료된 카드 정보
     * @throws CardNotFoundException 카드를 찾을 수 없는 경우
     */
    public CardDto.Response reviewCard(Long cardId, CardDto.ReviewRequest requestDto) {
        Card card = cardRepository.findById(cardId)
                .orElseThrow(() -> new CardNotFoundException(cardId));

        // 난이도 선택 = 복습 완료
        card.reviewWithDifficulty(requestDto.getDifficulty());

        // Dirty Checking으로 자동 저장
        return new CardDto.Response(card);
    }

    /**
     * 카드를 삭제함.
     *
     * @param cardId 카드 ID
     * @throws CardNotFoundException 카드를 찾을 수 없는 경우
     */
    public void deleteCard(Long cardId) {
        Card card = cardRepository.findById(cardId)
                .orElseThrow(() -> new CardNotFoundException(cardId));
        cardRepository.delete(card);
    }

    /**
     * 사용자의 모든 카드에 대한 난이도별 통계를 조회함.
     *
     * @param userId 사용자 ID
     * @return 난이도별 카드 통계
     */
    public CardDto.StatisticsResponse getCardStatisticsByUserId(Long userId) {
        long easyCount = cardRepository.countByWordBookUserIdAndDifficulty(userId, Card.Difficulty.EASY);
        long normalCount = cardRepository.countByWordBookUserIdAndDifficulty(userId, Card.Difficulty.NORMAL);
        long hardCount = cardRepository.countByWordBookUserIdAndDifficulty(userId, Card.Difficulty.HARD);

        return new CardDto.StatisticsResponse(easyCount, normalCount, hardCount);
    }

    /**
     * 특정 단어장의 카드에 대한 난이도별 통계를 조회함.
     *
     * @param wordBookId 단어장 ID
     * @return 난이도별 카드 통계
     */
    public CardDto.StatisticsResponse getCardStatisticsByWordBookId(Long wordBookId) {
        long easyCount = cardRepository.countByWordBookIdAndDifficulty(wordBookId, Card.Difficulty.EASY);
        long normalCount = cardRepository.countByWordBookIdAndDifficulty(wordBookId, Card.Difficulty.NORMAL);
        long hardCount = cardRepository.countByWordBookIdAndDifficulty(wordBookId, Card.Difficulty.HARD);

        return new CardDto.StatisticsResponse(easyCount, normalCount, hardCount);
    }
}