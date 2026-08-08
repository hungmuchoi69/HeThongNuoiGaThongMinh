package com.example.backend.controllers;

import java.util.HashMap;
import java.util.List;
import java.util.Map;


import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.backend.entities.LuaGa;
import com.example.backend.services.LichTiemThucTeService;
import com.example.backend.services.LuaGaService;

@RestController
@RequestMapping("/api/LuaGa")
public class LuaGaController {
    @Autowired
    private LuaGaService luaGaService;

    @Autowired
    private LichTiemThucTeService lichTiemThucTeService;

    @GetMapping
    public List<LuaGa> getAllLuaGas(){
        return luaGaService.getAllLuaGas();
    }

    @PostMapping
    public LuaGa createLuaGa(@RequestBody LuaGa luaGa){
        LuaGa saveLuaGa = luaGaService.createLuaGa(luaGa);
        lichTiemThucTeService.dongBoLichTiemLuaGa(saveLuaGa);
        return saveLuaGa;
    }

    @PutMapping("/{id}")
    public LuaGa updateLuaGa(@PathVariable int id, @RequestBody LuaGa luaGa){
        return luaGaService.updateLuaGa(id, luaGa);
    }

    @GetMapping("/{id}/{status}")
    public LuaGa getLuaGaById(@PathVariable String id, @PathVariable String status){
        return luaGaService.getLuaGaByUserId(id, status);
    }

    @GetMapping("/Check/{userId}")
    public ResponseEntity<?> checkActiveLuaGa(@PathVariable String userId){
        boolean hasActive = luaGaService.existsByUserIdAndStatus(userId, "RAISING");
        Map<String, Object> response = new HashMap<>();
        response.put("hasActiveLuaGa", hasActive);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/find/{id}")
    public LuaGa findByIDLG(@PathVariable int id){
        return luaGaService.findLuaGaByID(id);
    }

}
