package com.example.backend.controllers;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.backend.entities.LoaiChiPhi;
import com.example.backend.services.LoaiChiPhiService;

@RestController
@RequestMapping("/api/LoaiChiPhi")
public class LoaiChiPhiController {
    @Autowired
    private LoaiChiPhiService loaiChiPhiService;

    @GetMapping
    public List<LoaiChiPhi> getAllLoaiChiPhis(){
        return loaiChiPhiService.getAllChiPhis();
    }
}
