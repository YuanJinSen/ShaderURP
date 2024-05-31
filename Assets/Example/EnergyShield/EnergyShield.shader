Shader "MyURP/EnergyShield"
{
    Properties
    {
        [Header(High Light)]
        _HighLightFade("High Light Fade", Range(1, 10)) = 10
        _HighLightColor("High Light Color", color) = (1,1,1,1)

        [Header(Fresnel)]
        [PowerSlider(3)]_FresnelPow("Fresnel Pow", Range(1, 15)) = 7
        _FresnelColor("Fresnel Color", color) = (1,1,1,1)

        [Header(Flow Distort)]
        _FlowTiling("Flow Tiling", float) = 6
        _FlowDistort("Flow Distort", Range(0,1)) = 0.4
        _FlowMap("Base Map", 2D) = "white" {}
    }
 
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
 
        Pass
        {
            Name "EnergyShield"

            HLSLPROGRAM

            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
 
            struct Attributes
            {
                float4 positionOS       : POSITION;
                half3 normalOS          : NORMAL;
                float2 uv               : TEXCOORD0;
            };
 
            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float4 uv               : TEXCOORD0;
                float fogCoord          : TEXCOORD1;
                half positionVS_Z       : TEXCOORD2;
                half3 normalWS          : TEXCOORD3;
                half3 viewWs            : TEXCOORD4;
            };
 
            CBUFFER_START(UnityPerMaterial)
            half _HighLightFade;
            half4 _HighLightColor;
            half _FresnelPow;
            half4 _FresnelColor;
            half _FlowTiling;
            half _FlowDistort;
            float4 _FlowMap_ST;
            CBUFFER_END
            TEXTURE2D (_FlowMap);SAMPLER(sampler_FlowMap);
            TEXTURE2D (_CameraDepthTexture);SAMPLER(sampler_CameraDepthTexture);
            TEXTURE2D (_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);
 
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
 
                o.uv.xy = v.uv;
                o.uv.zw = TRANSFORM_TEX(v.uv, _FlowMap);

                //由于需要获取深度值（离相机越远越大），就需要View空间下的Z值
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                float3 positionVS = TransformWorldToView(positionWS);
                //由于都算到这了，TransformObjectToHClip内部也要做这么些事，不如节省一下，把值拿来用
                o.positionCS = TransformWViewToHClip(positionVS);
                o.positionVS_Z = -positionVS.z;

                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewWs = normalize(_WorldSpaceCameraPos - positionWS);
 
                return o;
            }
 
            half4 frag(Varyings i) : SV_Target
            {
                half4 c = 0;

                //---靠近物体部分高光---
                //获取片段对应深度图中像素在观察空间下的深度，0~正无穷
                float2 screenUV = i.positionCS.xy / _ScreenParams.xy;
                half4 depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
                //将值限制为0~1，符合View空间
                half depth = LinearEyeDepth(depthMap.r, _ZBufferParams);
                //计算边缘高光
                half delta = (depth - i.positionVS_Z) * _HighLightFade;
                half highLight = saturate(1 - delta);
                c += highLight * _HighLightColor;
                //---------------------

                //-----菲尼尔外发光-----
                //pow(max(0, dot(N,V)), Intensity)
                half3 N = i.normalWS;
                half3 V = i.viewWs;
                half NdotV =  1 - saturate(dot(N, V));
                half fresnel = pow(abs(NdotV), _FresnelPow);
                c += fresnel * _FresnelColor;
                //---------------------

                //--------扭曲流动--------
                half baseMap = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, i.uv.zw + float2(0, _Time.y)).r;
                c += baseMap * 0.05f;
                float2 distortUV = lerp(screenUV, baseMap, (1 - baseMap) * _FlowDistort);
                //抓屏
                half4 opaqueTex = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, distortUV);
                half flow = frac(i.uv.y * _FlowTiling + _Time.y);
                c += opaqueTex * flow;
                //-----------------------

                return c;
            }
            ENDHLSL
        }
    }
}