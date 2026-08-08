package com.example.backend.repositories;


import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.backend.entities.LuaGa;
@Repository
public interface LuaGaRepository extends JpaRepository<LuaGa,Integer> {
    @Query(value = "SELECT * FROM lua_ga WHERE trang_thai = :status", nativeQuery = true)
    List<LuaGa> findByTrangThai(@Param("status") String trangThai);

    @Query(value = "SELECT * FROM lua_ga WHERE user_id = :userId AND trang_thai = :status", nativeQuery = true)
    LuaGa findByUserId(@Param("userId") String id, @Param("status") String trangThai);

    @Query(value = "SELECT EXISTS(SELECT * FROM lua_ga WHERE user_id = :userId AND trang_thai = :status)", nativeQuery = true)
    boolean existsByUserIdAndStatus(@Param("userId") String id, @Param("status") String status);

    @Query(value = "SELECT * FROM lua_ga WHERE id = :id", nativeQuery = true)
    LuaGa findByIdLG(@Param("id") int id);
}
