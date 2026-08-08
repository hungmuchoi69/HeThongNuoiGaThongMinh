package com.example.backend.controllers;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.backend.entities.ThongBao;
import com.example.backend.services.ThongBaoService;

@RestController
@RequestMapping("/api/ThongBao")
public class ThongBaoController {
    @Autowired
    private ThongBaoService thongBaoService;

    @GetMapping("/{idLuaGa}")
    public List<ThongBao> getAllThongBaos(@PathVariable int idLuaGa){
        return thongBaoService.getAllThongBao(idLuaGa);
    }

    @PostMapping
    public ThongBao createThongBao(@RequestBody ThongBao thongBao){
        return thongBaoService.createThongBao(thongBao);
    }

    @GetMapping("/ChuaDoc/{id}")
    public ResponseEntity<?> getThongBaoChuaDoc(@PathVariable int id){
        int unRead= thongBaoService.getThongBaoChuaDoc(id);
        Map<String, Object> response = new HashMap<>();
        response.put("count", unRead);
        return ResponseEntity.ok(response);
    }


    @PutMapping("/read/{idThongBao}")
    public ResponseEntity<?> readNotification(@PathVariable int idThongBao, @RequestParam UUID userId, @RequestParam int idLuaGa){
        boolean res = thongBaoService.docMotThongBao(idThongBao, userId, idLuaGa);
        if(res){
            return ResponseEntity.ok("Đã đánh dấu đã đọc thông báo: " + idThongBao);
        }
        return ResponseEntity.badRequest().body("Không thể cập nhật trạng thái");
    }

    @PutMapping("/ReadAll")
    public ResponseEntity<?> readAllNotifications(@RequestParam int idLuaGa, @RequestParam UUID userId){
        boolean res=thongBaoService.docTatCaThongBao(idLuaGa, userId);
        if(res){
            return ResponseEntity.ok("Đã đọc hết thông báo của lứa gà: "+idLuaGa);
        }
        return ResponseEntity.badRequest().body("Không thể cập nhật trạng thái");
    }
}
