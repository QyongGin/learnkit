package com.learnkit.backend.domain;


import jakarta.persistence.Column;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.MappedSuperclass;
import lombok.Getter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

// created_at과 updated_at처럼 자주 사용되는 필드를 별도의 클래스로 분리하여 상속받아 사용하게 만듦.
// 이를 'JPA Auditing' 이라 한다.

@Getter
@MappedSuperclass // 이 클래스를 상속받는 엔티티들은 아래 필드를 컬럼으로 갖는다.
@EntityListeners(AuditingEntityListener.class) // 시간에 대한 변경을 감지하여 자동으로 값을 넣는다.
public class BaseTimeEntity {

    @CreatedDate // 엔티티가 생성될 때의 시간이 자동 저장됨
    @Column(updatable = false) // 생성 시간은 수정되지 않도록 설정
    private LocalDateTime createdAt;

    @LastModifiedDate // 엔티티의 값이 변경될 때의 시간이 자동 저장된다.
    private LocalDateTime updatedAt;
}
