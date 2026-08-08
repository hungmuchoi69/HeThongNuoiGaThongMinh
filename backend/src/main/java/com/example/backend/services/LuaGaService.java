package com.example.backend.services;

import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.example.backend.entities.LuaGa;
import com.example.backend.repositories.LuaGaRepository;

@Service
public class LuaGaService {
    @Autowired
    private LuaGaRepository luaGaRepository;

    public List<LuaGa> getAllLuaGas(){
        return luaGaRepository.findAll();
    }

    public LuaGa createLuaGa(LuaGa luaGa){
        DeviceHeartbeatManager.updateHeartbeat(luaGa.getId());
        return luaGaRepository.save(luaGa);
    }

    public LuaGa updateLuaGa(int id, LuaGa luaGa){
        Optional<LuaGa> lg= luaGaRepository.findById(id);
        if(lg.isPresent()){
            LuaGa existingLuaGa= lg.get();
            existingLuaGa.setGiong_ga(luaGa.getGiong_ga());
            existingLuaGa.setTen_lua(luaGa.getTen_lua());
            existingLuaGa.setSo_luong_ban_dau(luaGa.getSo_luong_ban_dau());
            existingLuaGa.setSo_luong_hien_tai(luaGa.getSo_luong_hien_tai());
            existingLuaGa.setNgay_nhap(luaGa.getNgay_nhap());
            existingLuaGa.setNgay_xuat_du_kien(luaGa.getNgay_xuat_du_kien());
            existingLuaGa.setTrang_thai(luaGa.getTrang_thai());
            existingLuaGa.setLoi_nhuan(luaGa.getLoi_nhuan());
            DeviceHeartbeatManager.removeDevice(id);
            return luaGaRepository.save(existingLuaGa);  
        }
        return null;
    }
    public LuaGa getLuaGaByUserId(String id, String trangThai){
        return luaGaRepository.findByUserId(id, trangThai);
    }

    public boolean existsByUserIdAndStatus(String id, String status){
        return luaGaRepository.existsByUserIdAndStatus(id, status);
    }

    public LuaGa findLuaGaByID(int id){
        return luaGaRepository.findByIdLG(id);
    }
}
