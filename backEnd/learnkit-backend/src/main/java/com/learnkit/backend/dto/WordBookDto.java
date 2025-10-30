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
        private String description;            // 선택사항
        private Integer hardFrequencyRatio;    // 선택사항 (null이면 기본값 6)
        private Integer normalFrequencyRatio;  // 선택사항 (null이면 기본값 3)
        private Integer easyFrequencyRatio;    // 선택사항 (null이면 기본값 1)

        public WordBook toEntity() {
            if (hardFrequencyRatio != null && normalFrequencyRatio != null && easyFrequencyRatio != null) {
                return new WordBook(this.title, this.description, this.hardFrequencyRatio, this.normalFrequencyRatio, this.easyFrequencyRatio);
            }
            return new WordBook(this.title, this.description);  // 기본값 사용
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
        private String description;
        private Integer hardFrequencyRatio;
        private Integer normalFrequencyRatio;
        private Integer easyFrequencyRatio;
    }

    /**
     * 단어장 응답 DTO
     */
    @Getter
    public static class Response {
        private final Long id;
        private final String title;
        private final String description;
        private final int hardFrequencyRatio;
        private final int normalFrequencyRatio;
        private final int easyFrequencyRatio;

        public Response(WordBook wordBook) {
            this.id = wordBook.getId();
            this.title = wordBook.getTitle();
            this.description = wordBook.getDescription();
            this.hardFrequencyRatio = wordBook.getHardFrequencyRatio();
            this.normalFrequencyRatio = wordBook.getNormalFrequencyRatio();
            this.easyFrequencyRatio = wordBook.getEasyFrequencyRatio();
        }
    }

}
