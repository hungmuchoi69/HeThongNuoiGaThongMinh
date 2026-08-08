package com.example.backend.controllers;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.backend.entities.ChiPhiChanNuoi;
import com.example.backend.services.ChiPhiChanNuoiService;

@RestController
@RequestMapping("/api/ChiPhiChanNuoi")
public class ChiPhiChanNuoiController {
    @Autowired
    private ChiPhiChanNuoiService chiPhiChanNuoiService;

    @GetMapping("/{id}")
    public List<ChiPhiChanNuoi> getAllChiPhiChanNuois(@PathVariable int id){
        return chiPhiChanNuoiService.getAllChiPhiChanNuois(id);
    }

    @PostMapping
    public ChiPhiChanNuoi createChiPhiChanNuoi(@RequestBody ChiPhiChanNuoi chiPhiChanNuoi){
        return chiPhiChanNuoiService.createChiPhiChanNuoi(chiPhiChanNuoi);
    }

    @PutMapping("/{id}")
    public ChiPhiChanNuoi updateChiPhiChanNuoi(@PathVariable int id, @RequestBody ChiPhiChanNuoi chiPhiChanNuoi){
        return chiPhiChanNuoiService.updateChiPhiChanNuoi(id, chiPhiChanNuoi);
    }
}
