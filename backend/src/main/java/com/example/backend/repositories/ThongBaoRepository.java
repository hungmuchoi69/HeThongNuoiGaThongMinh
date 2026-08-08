package com.example.backend.repositories;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import com.example.backend.entities.ThongBao;

@Repository
public interface ThongBaoRepository  extends JpaRepository<ThongBao,Integer>{
    @Query(value = "SELECT COUNT(*) FROM thong_bao WHERE id_lua_ga = :idLuaGa AND da_doc = false", nativeQuery = true)
    int getThongBaoChuaDoc(@Param("idLuaGa") int id);

    @Query(value = "SELECT * FROM thong_bao WHERE id_lua_ga = :idLuaGa ORDER BY thoi_gian_tao DESC",nativeQuery = true)
    List<ThongBao> geThongBaoByLuaga(@Param("idLuaGa") int idLuaGa);

    @Transactional
    @Modifying
    @Query(value = "UPDATE thong_bao SET da_doc = true WHERE id = :id", nativeQuery = true)
    int markAsRead(@Param("id") int id);

    @Transactional
    @Modifying
    @Query(value = "UPDATE thong_bao SET da_doc = true WHERE id_lua_ga = :idLuaGa", nativeQuery = true)
    int markAllRead(@Param("idLuaGa") int idLuaGa);
}
