//
//  OpenGLShaderProgram.swift
//  OpenGLKit
//
//  Created by lunner on 2018/7/16.
//  Copyright © 2018 lunner. All rights reserved.
//

import Foundation
import OpenGLES
import GLKit

class GLProgram {
    var program: GLuint = GLuint()
    var attributes = [String]()
    
    var shaders = [GLenum: GLuint]()
    
    deinit {
        for (_, shader) in shaders {
            glDeleteShader(shader)
        }
        glDeleteProgram(program)
    }
    init() {
        program = glCreateProgram()
        if program == 0 {
            print("Create Program Error!")
        }
    }
    
    @discardableResult
    func addShaderFromFile(type: GLenum, file: String) -> Bool {
        if let source = GLProgram.shaderSourceFromFile(path: file), !source.isEmpty {
            return self.addShaderFromSource(type: type, source: source)
        } else {
            #if DEBUG
            print("Load Shader source file failed: \(file)")
            #endif
            return false
        }
    }
    
    @discardableResult
    func addShaderFromSource(type: GLenum, source: String) -> Bool {
        guard type != GL_NONE else {
            return false
        }
        guard program != 0 else {
            return false
        }
        let shader: GLuint = glCreateShader(type)
        guard shader != 0 else {
            return false
        }
        
        if let oldShader = shaders[type] {
            glDetachShader(program, oldShader)
            glDeleteShader(oldShader)
        }
        shaders[type] = shader
        
        let cString = source.cString(using: String.Encoding.utf8)
        var stringPointer = UnsafePointer<GLchar>(cString)
        glShaderSource(shader, 1, &stringPointer, nil)
        glCompileShader(shader)
        
        var compiled = GL_FALSE
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &compiled)
        guard compiled == GL_TRUE else {
            GLProgram.checkShaderStatus(shader: shader)
            glDeleteShader(shader)
            shaders[type] = nil
            return false
        }
        
        glAttachShader(program, shader)
        
        return true
    }
    
    @discardableResult
    func link() -> Bool {
        return GLProgram.link(program: program)
    }
    
    func use() {
        glUseProgram(program)
    }
    
    func validate() {
        glValidateProgram(program)
        GLProgram.checkProgramStatus(program: program)
    }
    
    func getUniformLocation(name: String) -> GLint {
        let cString = name.cString(using: String.Encoding.utf8)
        let stringPointer = UnsafePointer<GLchar>(cString)
        let location = glGetUniformLocation(program, stringPointer)
        return location
    }
    
    func addAttribute(attribute: String) {
        if attributes.contains(attribute) {
            return
        }
        attributes.append(attribute)
        let index = attributes.index(of: attribute)!
        let cString = attribute.cString(using: String.Encoding.utf8)
        let stringPointer = UnsafePointer<GLchar>(cString)
        glBindAttribLocation(program, GLuint(index), stringPointer)
        
    }

    
    func getAttributeLocation(name: String) -> GLint {
        let cString = name.cString(using: String.Encoding.utf8)
        let stringPointer = UnsafePointer<GLchar>(cString)
        let location = glGetAttribLocation(program, stringPointer)
        return location
    }
    
}

extension GLProgram {
    // Because validating a program checks it against the entire OpenGL ES context state, it is an expensive operation. Since the results of program validation are only meaningful during development, you should not call this function in Release builds of your app.
    class func checkProgramStatus(program: GLuint) {
        #if DEBUG
        var logLen = GLint()
        // Check the status of the compile/link
        glGetProgramiv(program, GLenum(GL_INFO_LOG_LENGTH), &logLen)
        var log = [GLchar](repeating: GLchar(0), count: Int(logLen))
        if logLen > 0 {
            // Show any errors as appropriate
            glGetProgramInfoLog(program, logLen, &logLen, &log)
            print("Program Info Log: \(String(utf8String: log)!)")
        }
        #endif
    }
    class func checkShaderStatus(shader: GLuint) {
        #if DEBUG
        var logLen = GLint()
        // Check the status of the compile/link
        glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLen)
        var log = [GLchar](repeating: GLchar(0), count: Int(logLen))
        if logLen > 0 {
            // Show any errors as appropriate
            glGetShaderInfoLog(shader, logLen, &logLen, &log)
            print("Shader Info Log: \(String(utf8String: log)!)")
        }
        #endif
    }
    
    
    class func validateProgram(program: GLuint, success: inout Bool) {
        #if DEBUG
        glValidateProgram(program)
        var result = GLint()
        glGetProgramiv(program, GLenum(GL_VALIDATE_STATUS), &result)
        if result == GL_TRUE {
            success = true
        } else {
            success = false
        }
        #endif
    }
    
    class func shaderSourceFromFile(path: String) -> String? {
        let source = try? String(contentsOfFile: path)
        return source
    }
    
    @discardableResult
    class func addShaderFromFile(program: GLuint, vertexFile: String, fragmentFile: String) -> Bool {
        if let vertexSource = GLProgram.shaderSourceFromFile(path: vertexFile), let fragmentSource = GLProgram.shaderSourceFromFile(path: fragmentFile) {
            return GLProgram.addShadersFromSource(program:program, vertexSource:vertexSource, fragmentSource:fragmentSource)
        } else {
            #if DEBUG
            print("Load Shader source file failed: \(vertexFile) \(fragmentFile)")
            #endif
            return false
        }
    }
    private class func addShaderFromSource(program: GLuint, type: GLenum, source: String) -> GLuint {
        let shader: GLuint = glCreateShader(type)
        guard shader != 0 else {
            return 0
        }
        let cString = source.cString(using: String.Encoding.utf8)
        var stringPointer = UnsafePointer<GLchar>(cString)
        glShaderSource(shader, 1, &stringPointer, nil)
        glCompileShader(shader)
        
        var compiled = GL_FALSE
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &compiled)
        guard compiled == GL_TRUE else {
            GLProgram.checkShaderStatus(shader: shader)
            glDeleteShader(shader)
            return 0
        }
        
        glAttachShader(program, shader)
        return shader
    }
    
    @discardableResult
    class func addShadersFromSource(program: GLuint, vertexSource: String, fragmentSource: String) -> Bool {
        guard program != 0 else {
            return false
        }
        let vertexShader = self.addShaderFromSource(program: program, type: GLenum(GL_VERTEX_SHADER), source: vertexSource)
        let fragmentShader = self.addShaderFromSource(program: program, type: GLenum(GL_FRAGMENT_SHADER), source: fragmentSource)
        GLProgram.link(program: program)
        glDeleteShader(vertexShader)
        glDeleteShader(fragmentShader)
        return true
    }
    
    @discardableResult
    class func link(program: GLuint) -> Bool {
        glLinkProgram(program)
        var linked = GL_FALSE
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &linked)
//        if linked != GL_TRUE {
            GLProgram.checkProgramStatus(program: program)
//            return false
//        }
        return true
    }
}
