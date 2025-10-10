package com.learnkit.backend.repository;


import com.learnkit.backend.domain.WordBook;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface WordBookRepository extends JpaRepository<WordBook, Long> {

    // JpaRepository: save, findByID, findAll, deleteById 기본 메소드 제공.

    // 유저에게 속한 단어장 조회
    List<WordBook> findByUserId(Long userId);

}
