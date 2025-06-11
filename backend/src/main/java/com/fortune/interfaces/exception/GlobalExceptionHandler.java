package com.fortune.interfaces.exception;

import java.sql.SQLException;
import javax.validation.ConstraintViolationException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.bind.MethodArgumentNotValidException;

/**
 * 全局异常处理器
 * 捕获所有控制器抛出的异常，并以统一格式返回
 */
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /**
     * 处理数据库异常
     */
    @ExceptionHandler({SQLException.class, DataAccessException.class})
    public ResponseEntity<ErrorResponse> handleDatabaseException(Exception ex) {
        logger.error("数据库异常：", ex);
        ErrorResponse response = new ErrorResponse(
            "DATABASE_ERROR", 
            "数据库操作失败，请稍后重试",
            ex.getMessage()
        );
        return new ResponseEntity<>(response, HttpStatus.SERVICE_UNAVAILABLE);
    }
    
    /**
     * 处理参数验证异常
     */
    @ExceptionHandler({MethodArgumentNotValidException.class, ConstraintViolationException.class})
    public ResponseEntity<ErrorResponse> handleValidationExceptions(Exception ex) {
        logger.warn("参数验证失败：", ex);
        ErrorResponse response = new ErrorResponse(
            "VALIDATION_ERROR", 
            "请求参数不符合要求",
            ex.getMessage()
        );
        return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
    }
    
    /**
     * 处理参数类型不匹配异常
     */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ErrorResponse> handleTypeMismatch(MethodArgumentTypeMismatchException ex) {
        logger.warn("参数类型不匹配：", ex);
        ErrorResponse response = new ErrorResponse(
            "TYPE_MISMATCH", 
            "参数类型不匹配",
            "参数 " + ex.getName() + " 应为 " + ex.getRequiredType().getSimpleName() + " 类型"
        );
        return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
    }
    
    /**
     * 默认异常处理
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGenericException(Exception ex) {
        logger.error("未处理异常：", ex);
        ErrorResponse response = new ErrorResponse(
            "INTERNAL_ERROR", 
            "服务器内部错误，请稍后重试",
            ex.getMessage()
        );
        return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
    }
    
    /**
     * 错误响应对象
     */
    static class ErrorResponse {
        private final String code;
        private final String message;
        private final String details;
        private final long timestamp;
        
        public ErrorResponse(String code, String message, String details) {
            this.code = code;
            this.message = message;
            this.details = details;
            this.timestamp = System.currentTimeMillis();
        }
        
        public String getCode() {
            return code;
        }
        
        public String getMessage() {
            return message;
        }
        
        public String getDetails() {
            return details;
        }
        
        public long getTimestamp() {
            return timestamp;
        }
    }
} 