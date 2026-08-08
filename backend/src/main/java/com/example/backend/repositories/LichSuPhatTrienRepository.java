package com.example.backend.repositories;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.backend.entities.LichSuPhatTrien;
@Repository
public interface LichSuPhatTrienRepository extends JpaRepository<LichSuPhatTrien,Integer> {
    
    @Query(value = "SELECT * FROM lich_su_phat_trien WHERE id_lua_ga = :idLuaGa", nativeQuery = true)
    List<LichSuPhatTrien> getLichSuPhatTrienByLuaGa(@Param("idLuaGa") int idLuaGa);

    @Query(value = "SELECT * FROM lich_su_phat_trien WHERE id_lua_ga = :idLuaGa AND ngay = :ngay", nativeQuery = true)
    Optional<LichSuPhatTrien> getLSByIdVaNgay(@Param("idLuaGa") int idLuaGa, @Param("ngay") LocalDate ngay);

}
