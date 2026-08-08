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
@Table(name = "CAM_BIEN_HOM_NAY")
@Data
public class CamBienHomNay {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;
    private float nhiet_do;
    private float do_am;
    private int tds;
    private boolean silo_status;
    private int gas;
    private LocalDateTime logged_at;

    @ManyToOne
    @JoinColumn(name = "id_lua_ga")
    @JsonIgnore
    private LuaGa luaGa;
}
