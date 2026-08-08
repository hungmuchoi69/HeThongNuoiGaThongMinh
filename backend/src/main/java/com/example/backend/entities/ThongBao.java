package com.example.backend.entities;

import java.time.LocalDateTime;

import com.fasterxml.jackson.annotation.JsonIgnore;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "THONG_BAO")
@Data
public class ThongBao {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;
    private String tieu_de;
    private String noi_dung;
    private String loai_tb;//thông báo trường hợp khẩn cấp hay thông báo nhắc nhỏ công tác chăn nuôi
    private boolean da_doc;
    private LocalDateTime thoi_gian_tao;

    @ManyToOne
    @JoinColumn(name = "id_lua_ga")
    @JsonIgnore
    private LuaGa luaGa;
}