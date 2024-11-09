// src/components/ShaderBackground.tsx

"use client";
import React, { useEffect, useRef } from 'react';
import * as THREE from 'three';

let scene: THREE.Scene, camera: THREE.OrthographicCamera, renderer: THREE.WebGLRenderer, geometry: THREE.PlaneGeometry, material: THREE.ShaderMaterial, mesh: THREE.Mesh;

const fragmentShader = `
uniform vec2 uResolution;
varying vec2 vUv;

float line(float pos, float width) {
    return smoothstep(width, 0.0, abs(pos));
}

void main() {
    vec2 uv = gl_FragCoord.xy / uResolution.xy;
    vec3 paperColor = vec3(0.98, 0.97, 0.95);
    vec3 lineColor = vec3(0.7, 0.84, 0.95);
    
    // Vertical red margin line
    float marginLine = line(uv.x - 0.08, 0.002);
    vec3 color = mix(paperColor, vec3(0.85, 0.3, 0.3), marginLine);

    // Horizontal blue lines
    float lineSpacing = 1.0 / 35.0; // Adjust for wider rule
    for(float i = 0.0; i < 1.0; i += lineSpacing) {
        float horizontalLine = line(uv.y - i, 0.0005);
        color = mix(color, lineColor, horizontalLine * 0.5);
    }

    // Add some paper texture
    float noise = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
    color *= 0.95 + 0.05 * noise;

    gl_FragColor = vec4(color, 1.0);
}
`;

const vertexShader = `
varying vec2 vUv;
void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
`;

function init() {
    scene = new THREE.Scene();
    camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0.1, 10);

    const canvas = document.getElementById('shaderBackgroundCanvas') as HTMLCanvasElement;
    renderer = new THREE.WebGLRenderer({ canvas });
    renderer.setSize(window.innerWidth, window.innerHeight);

    geometry = new THREE.PlaneGeometry(2, 2);

    material = new THREE.ShaderMaterial({
        uniforms: {
            uResolution: { value: new THREE.Vector2(window.innerWidth, window.innerHeight) }
        },
        vertexShader: vertexShader,
        fragmentShader: fragmentShader
    });

    mesh = new THREE.Mesh(geometry, material);
    scene.add(mesh);

    camera.position.z = 1;

    animate();
}

function animate() {
    requestAnimationFrame(animate);
    renderer.render(scene, camera);
}

function onWindowResize() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    material.uniforms.uResolution.value.set(window.innerWidth, window.innerHeight);
}

const ShaderBackground: React.FC = () => {
    const canvasRef = useRef<HTMLCanvasElement>(null);

    useEffect(() => {
        if (canvasRef.current) {
            canvasRef.current.id = 'shaderBackgroundCanvas';
            init();
            window.addEventListener('resize', onWindowResize);
        }

        return () => {
            window.removeEventListener('resize', onWindowResize);
        };
    }, []);

    return <canvas ref={canvasRef} style={{ position: 'fixed', top: 0, left: 0, zIndex: -1 }} />;
};

export default ShaderBackground;