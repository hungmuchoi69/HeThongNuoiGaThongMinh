package com.example.backend.controllers;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.backend.entities.CamBienHomNay;
import com.example.backend.services.CamBienHomNayService;

@RestController
@RequestMapping("/api/CamBienHomNay")
public class CamBienHomNayController {
    @Autowired
    private CamBienHomNayService camBienHomNayService;

    @GetMapping("/{idLuaGa}")
    public List<CamBienHomNay> getAllcCamBienHomNays(@PathVariable int idLuaGa){
        return camBienHomNayService.getAllCamBienHomNaysByIdLuaGa(idLuaGa);
    }

    @PostMapping
    public CamBienHomNay createCamBienHomNay(@RequestBody CamBienHomNay camBienHomNay){
        return camBienHomNayService.createCamBienHomNay(camBienHomNay);
    }
}
