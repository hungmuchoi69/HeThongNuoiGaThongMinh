package com.example.backend.repositories;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.backend.entities.LichTiemThucTe;
@Repository
public interface LichTiemThucTeRepository extends JpaRepository<LichTiemThucTe, Integer> {
    @Query(value = "SELECT * FROM lich_tiem_thuc_te " +
                   "WHERE id_lua_ga = :idLuaGa", 
                   nativeQuery = true)
    List<LichTiemThucTe> getLichTiemThucTeByLuaGa(@Param("idLuaGa") int idLuaGa);
}
