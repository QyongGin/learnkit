package com.learnkit.backend.controller;


import com.learnkit.backend.dto.WordBookDto;
import com.learnkit.backend.service.WordBookService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController // 내부적으로 @ResponseBody를 모든 메서드에 자동 적용. 메서드의 반환값을 HTTP 응답 본문에 JSON으로 변환하여 넣음. JSON API라고 선언.
@RequestMapping("/api")
@RequiredArgsConstructor // final 필드에 대한 생성자 생성
public class WordBookController {

    private final WordBookService wordBookService;

    // 단어장 생성
    @PostMapping("/users/{userId}/wordbooks")
    public ResponseEntity<WordBookDto.Response> createWordBook(@PathVariable Long userId, @RequestBody WordBookDto.CreateRequest requestDto) {
        WordBookDto.Response responseDto = wordBookService.createWordBook(userId, requestDto);
        return ResponseEntity.status(HttpStatus.CREATED).body(responseDto);
    }

    // 특정 사용자의 모든 단어장 조회
    @GetMapping("/users/{userId}/wordbooks")
    public ResponseEntity<List<WordBookDto.Response>> getWordBooksByUserId(@PathVariable Long userId) {
        List<WordBookDto.Response> responseDtos = wordBookService.findWordBooksByUserId(userId);
        return ResponseEntity.ok(responseDtos);
    }

    // 단어장 상세 조회
    @GetMapping("/wordbooks/{wordBookId}")
    public ResponseEntity<WordBookDto.Response> getWordBookById(@PathVariable Long wordBookId) {
        WordBookDto.Response responseDto = wordBookService.findWordBookById(wordBookId);
        return ResponseEntity.ok(responseDto);
    }

    // 단어장 수정
    @PatchMapping("/wordbooks/{wordBookId}")
    public ResponseEntity<WordBookDto.Response> updateWordBook(@PathVariable Long wordBookId,
                                                               @RequestBody WordBookDto.UpdateRequest requestDto) {
        WordBookDto.Response responseDto = wordBookService.updateWordBook(wordBookId, requestDto);
        return ResponseEntity.ok(responseDto);
    }

    // 단어장 삭제
    @DeleteMapping("/wordbooks/{wordBookId}")
    public ResponseEntity<Void> deleteWordBook(@PathVariable Long wordBookId) {
        wordBookService.deleteWordBook(wordBookId);
        return ResponseEntity.noContent().build(); // 204
    }

}