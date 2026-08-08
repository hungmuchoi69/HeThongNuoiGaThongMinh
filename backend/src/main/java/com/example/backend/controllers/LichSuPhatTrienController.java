package com.example.backend.controllers;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.backend.entities.LichSuPhatTrien;
import com.example.backend.services.LichSuPhatTrienService;

@RestController
@RequestMapping("/api/LichSuPhatTrien")
public class LichSuPhatTrienController {
    @Autowired
    private LichSuPhatTrienService lichSuPhatTrienService;

    @GetMapping("/{idLuaGa}")
    public List<LichSuPhatTrien> getAllLichSuPhatTriens(@PathVariable int idLuaGa){
        return lichSuPhatTrienService.getAllLichSuPhatTriens(idLuaGa);
    }


    @PostMapping
    public LichSuPhatTrien createLichSuPhatTrien(@RequestBody LichSuPhatTrien lichSuPhatTrien){
        return lichSuPhatTrienService.createLichSuPhatTrien(lichSuPhatTrien);
    }
}
