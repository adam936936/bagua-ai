package com.fortune.interfaces.dto.response;

import java.io.Serializable;

/**
 * API统一响应格式
 *
 * @param <T> 数据类型
 */
public class ApiResponse<T> implements Serializable {
    private static final long serialVersionUID = 1L;

    private boolean success;
    private String message;
    private T data;
    private String code;
    private String warning;

    private ApiResponse() {
    }

    public static <T> ApiResponse<T> success() {
        ApiResponse<T> response = new ApiResponse<>();
        response.setSuccess(true);
        response.setMessage("操作成功");
        response.setCode("200");
        return response;
    }

    public static <T> ApiResponse<T> success(T data) {
        ApiResponse<T> response = success();
        response.setData(data);
        return response;
    }

    /**
     * 成功但有警告信息
     */
    public static <T> ApiResponse<T> successWithWarning(T data, String warning) {
        ApiResponse<T> response = success(data);
        response.setWarning(warning);
        return response;
    }

    public static <T> ApiResponse<T> error(String message) {
        ApiResponse<T> response = new ApiResponse<>();
        response.setSuccess(false);
        response.setMessage(message);
        response.setCode("500");
        return response;
    }

    public static <T> ApiResponse<T> error(String code, String message) {
        ApiResponse<T> response = new ApiResponse<>();
        response.setSuccess(false);
        response.setMessage(message);
        response.setCode(code);
        return response;
    }

    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public T getData() {
        return data;
    }

    public void setData(T data) {
        this.data = data;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getWarning() {
        return warning;
    }

    public void setWarning(String warning) {
        this.warning = warning;
    }
} 