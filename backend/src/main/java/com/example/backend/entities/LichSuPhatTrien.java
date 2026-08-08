package com.example.backend.entities;

import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Data;
@Entity
@Table(name = "LICH_SU_PHAT_TRIEN")
@Data
public class LichSuPhatTrien {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;
    private LocalDate ngay;
    private float nhiet_do_tb;
    private float do_am_tb;
    private float tds_tb;
    private Float trong_luong_tb;
    private Float he_so_FCR;
    private Float ti_le_song;
    private Float gas_tb;

    @ManyToOne
    @JoinColumn(name = "id_lua_ga")
    @JsonProperty("luaGa")
    private LuaGa luaGa;
}
