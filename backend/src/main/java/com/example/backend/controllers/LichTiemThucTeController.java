package com.example.backend.controllers;


import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.backend.entities.LichTiemThucTe;
import com.example.backend.services.LichTiemThucTeService;

@RestController
@RequestMapping("/api/LichTiemThucTe")
public class LichTiemThucTeController {
    @Autowired
    private LichTiemThucTeService lichTiemThucTeService;

    @PutMapping("/{id}")
    public LichTiemThucTe updateLichTiemThucTe(@PathVariable int id, @RequestBody LichTiemThucTe lichTiemThucTe){
        return lichTiemThucTeService.updateLichTiemThucTe(id, lichTiemThucTe);
    }

    @GetMapping("/LuaGa/{idLuaGa}")
    public List<LichTiemThucTe> gLichTiemThucTes(@PathVariable int idLuaGa){
        return lichTiemThucTeService.getLichTiemThucTes(idLuaGa);
    }

}
