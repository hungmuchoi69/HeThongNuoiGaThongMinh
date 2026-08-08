package com.example.backend.entities;

import java.time.LocalDate;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "LUA_GA")
@Data
public class LuaGa {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;
    private String ten_lua;
    private String giong_ga;
    private int so_luong_ban_dau;
    private int so_luong_hien_tai;
    private LocalDate ngay_nhap;
    private LocalDate ngay_xuat_du_kien;
    private String trang_thai;
    private int loi_nhuan;
    @JsonProperty("user_id")
    @Column(name = "user_id")
    private String userId;

    @OneToMany(mappedBy = "luaGa", cascade = CascadeType.ALL)
    @JsonIgnore
    private List<LichTiemThucTe> lichTiemThucTes;

    @OneToMany(mappedBy = "luaGa", cascade = CascadeType.ALL)
    @JsonIgnore
    private List<LichSuPhatTrien> lichSuPhatTriens;

    @OneToMany(mappedBy = "luaGa", cascade = CascadeType.ALL)
    @JsonIgnore
    private List<ChiPhiChanNuoi> chiPhiChanNuois;

    @OneToMany(mappedBy = "luaGa", cascade = CascadeType.ALL)
    @JsonIgnore
    private List<ThongBao> thongBaos;

    @OneToMany(mappedBy = "luaGa", cascade = CascadeType.ALL)
    @JsonIgnore
    private List<CamBienHomNay> camBienHomNays;
}
