package com.learnkit.backend.service;


import com.learnkit.backend.domain.User;
import com.learnkit.backend.domain.WordBook;
import com.learnkit.backend.dto.WordBookDto;
import com.learnkit.backend.exception.custom.UserNotFoundException;
import com.learnkit.backend.exception.custom.WordBookNotFoundException;
import com.learnkit.backend.repository.UserRepository;
import com.learnkit.backend.repository.WordBookRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service // 비즈니스 로직을 담당하는 Service 컴포넌트임을 스프링에게 알린다.
@RequiredArgsConstructor // final 필드에 대한 생성자를 자동으로 만들어주는 롬복 어노테이션.
@Transactional  // 감시하던 wordBook 객체의 변화를 감지(Dirty Checking)하고 update 쿼리 실행.
public class WordBookService {

    private final WordBookRepository wordBookRepository;
    private final UserRepository userRepository;


    /**
     * 사용자의 새로운 단어장을 생성함.
     *
     * @param userId 단어장을 생성할 사용자의 ID
     * @param requestDto 단어장 생성 정보 (제목, 간격 설정)
     * @return 생성된 단어장 정보
     * @throws UserNotFoundException 사용자를 찾을 수 없는 경우
     */
    public WordBookDto.Response createWordBook(Long userId, WordBookDto.CreateRequest requestDto) {
        // 사용자 정보 조회
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException(userId));

        // DTO를 Entity로 변환하고, 사용자 정보 설정
        WordBook wordBook = requestDto.toEntity();
        wordBook.setUser(user); // wordBook이 속한 user 설정

        // DB에 저장, @LastModifiedDate에 의하여 BaseTimeEntity의 updatedAt도 저장
        WordBook savedWordBook = wordBookRepository.save(wordBook);

        // Entity를 Response DTO로 변환하여 반환
        return new WordBookDto.Response(savedWordBook);
    }

    /**
     * 특정 사용자의 모든 단어장을 조회함.
     *
     * @param userId 조회할 사용자의 ID
     * @return 사용자의 단어장 목록
     */
    public List<WordBookDto.Response> findWordBooksByUserId(Long userId) {
        List<WordBook> wordBooks = wordBookRepository.findByUserId(userId);
        return wordBooks.stream()
                .map(WordBookDto.Response::new)
                .toList();
    }

    /**
     * 특정 단어장의 상세 정보를 조회함.
     *
     * @param wordBookId 조회할 단어장의 ID
     * @return 단어장 상세 정보
     * @throws WordBookNotFoundException 단어장을 찾을 수 없는 경우
     */
    public WordBookDto.Response findWordBookById(Long wordBookId) {
        WordBook wordBook = wordBookRepository.findById(wordBookId)
                .orElseThrow(() -> new WordBookNotFoundException(wordBookId));
        return new WordBookDto.Response(wordBook);
    }

    /**
     * 단어장 정보를 수정함.
     *
     * @param wordBookId 수정할 단어장의 ID
     * @param requestDto 수정할 정보 (제목, 간격 설정)
     * @return 수정된 단어장 정보
     * @throws WordBookNotFoundException 단어장을 찾을 수 없는 경우
     */
    public WordBookDto.Response updateWordBook(Long wordBookId, WordBookDto.UpdateRequest requestDto) {
        WordBook wordBook = wordBookRepository.findById(wordBookId)
                .orElseThrow(() -> new WordBookNotFoundException(wordBookId));

        wordBook.update(
                requestDto.getTitle(),
                requestDto.getDescription(),
                requestDto.getHardFrequencyRatio(),
                requestDto.getNormalFrequencyRatio(),
                requestDto.getEasyFrequencyRatio()
        );

        return new WordBookDto.Response(wordBook);
    }

    /**
     * 단어장을 삭제함.
     *
     * @param wordBookId 삭제할 단어장의 ID
     * @throws WordBookNotFoundException 단어장을 찾을 수 없는 경우
     */
    public void deleteWordBook(Long wordBookId) {
        WordBook wordBook = wordBookRepository.findById(wordBookId)
                .orElseThrow(() -> new WordBookNotFoundException(wordBookId));
        wordBookRepository.delete(wordBook);
    }
}