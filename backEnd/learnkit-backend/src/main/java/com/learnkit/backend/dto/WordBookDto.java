package com.learnkit.backend.dto;

import com.learnkit.backend.domain.WordBook;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * WordBook(단어장) 관련 DTO들을 관리하는 클래스
 */
public class WordBookDto {


    /**
     * 단어장 생성 요청 DTO
     * <p>POST /users/{userId}/wordbooks</p>
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class CreateRequest {
        private String title;
        private int easyIntervalMinutes;
        private int normalIntervalMinutes;
        private int hardIntervalMinutes;

        // 전달용 상자(DTO)에 든 데이터를 Entity로 꺼내서 실제 데이터로 만들기.
        public WordBook toEntity() {
            return new WordBook(
                    this.title,
                    this.easyIntervalMinutes,
                    this.normalIntervalMinutes,
                    this.hardIntervalMinutes
            );
        }
    }

    /**
     * 단어장 수정 요청 DTO
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class UpdateRequest {
        private String title;
        private int easyIntervalMinutes;
        private int normalIntervalMinutes;
        private int hardIntervalMinutes;
    }

    /**
     * 단어장 응답 DTO
     */
    @Getter
    public static class Response {
        private final Long id;
        private final String title;
        private final int easyIntervalMinutes;
        private final int normalIntervalMinutes;
        private final int hardIntervalMinutes;

        public Response(WordBook wordBook) {
            this.id = wordBook.getId();
            this.title = wordBook.getTitle();
            this.easyIntervalMinutes = wordBook.getEasyIntervalMinutes();
            this.normalIntervalMinutes = wordBook.getNormalIntervalMinutes();
            this.hardIntervalMinutes = wordBook.getHardIntervalMinutes();
        }



    }

}
