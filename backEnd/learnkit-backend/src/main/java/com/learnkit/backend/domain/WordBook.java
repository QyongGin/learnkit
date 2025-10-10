package com.learnkit.backend.domain;


import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;


/**
 * 하나의 주제로 여러 단어(카드)가 모인 단어장
 */
@Getter
@Entity
@Table(name="wordbooks")
@NoArgsConstructor
public class WordBook extends BaseTimeEntity{

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false)
    private int easyIntervalMinutes = 20; // 쉬움: 20분

    @Column(nullable = false)
    private int normalIntervalMinutes = 10;

    @Column(nullable = false)
    private int hardIntervalMinutes = 3;

    // 클라이언트에서 받아온 DTO만으로는 WordBook을 만들지 못한다. 실제 Entity로 만들어야 하기 때문에 생성자 선언.
    public WordBook(String title, int easyIntervalMinutes, int normalIntervalMinutes, int hardIntervalMinutes) {
        this.title = title;
        this.easyIntervalMinutes = easyIntervalMinutes;
        this.normalIntervalMinutes = normalIntervalMinutes;
        this.hardIntervalMinutes = hardIntervalMinutes;
    }

    public void setUser(User user){
        this.user = user;
    }

    public void update(String title, Integer easyIntervalMinutes, Integer normalIntervalMinutes, Integer hardIntervalMinutes) {
        if (title != null) {
            this.title = title;
        }
        if (easyIntervalMinutes != null) {
            this.easyIntervalMinutes = easyIntervalMinutes;
        }
        if (normalIntervalMinutes != null) {
            this.normalIntervalMinutes = normalIntervalMinutes;
        }
        if (hardIntervalMinutes != null) {
            this.hardIntervalMinutes = hardIntervalMinutes;
        }
    }
}
