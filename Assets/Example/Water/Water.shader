Shader "MyURP/Water"
{
    Properties
    {
        [Header(Main)]
        _Depth("Depth", Range(0,0.1)) = 0
        _Speed("Speed", Range(0, 1)) = 1
        _Lightness("Lightness", float) = 1
        [Header(Foam)]
        _FoamTex("Foam Tex", 2D) = "white" {}
        _FoamRange("Foam Range", Range(0, 15)) = 1
        _FoamSize("Foam Size", Range(0, 3)) = 1
        _FoamColor("Foam Color", color) = (1,1,1,1)
        [Header(Distort)]
        _Distort("Distort", Range(0,0.1)) = 0
        _NormalTex("Normal Tex", 2D) = "white" {}
        [Header(Specular)]
        _SpecularColor("Specular Color", color) = (1,1,1,1)
        _Specular("Specular", float) = 1
        _Smoothness("Smoothness", float) = 1
        [Header(Reflection)]
        _ReflectionCube("Reflection Cube", cube) = "white" {}
        _ReflectionPow("Reflection Pow", float) = 1
        [Header(Caustic)]
        _CausticTex("CausticTex", 2D) = "white" {}
        _CausticInstensity("Caustic Instensity", float) = 1
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
 
        Pass
        {
            Name "Water"
            //Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM

            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
 
            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
            };
 
            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float4 uv               : TEXCOORD0;
                float4 normalUV         : TEXCOORD1;
                float fogCoord          : TEXCOORD2;
                float3 positionWS       : TEXCOORD3;
                float3 positionVS       : TEXCOORD4;
            };
 
            CBUFFER_START(UnityPerMaterial)
            half _Speed;
            half _Depth;
            half _Lightness;

            half4 _FoamColor;
            half _FoamRange;
            half _FoamSize;
            float4 _FoamTex_ST;

            half _Distort;
            float4 _NormalTex_ST;

            half4 _SpecularColor;
            half _Specular;
            half _Smoothness;

            half _ReflectionPow;

            float4 _CausticTex_ST;
            half _CausticInstensity;
            CBUFFER_END
            TEXTURE2D (_FoamTex);SAMPLER(sampler_FoamTex);
            TEXTURE2D (_NormalTex);SAMPLER(sampler_NormalTex);
            TEXTURECUBE (_ReflectionCube);SAMPLER(sampler_ReflectionCube);
            TEXTURE2D (_CausticTex);SAMPLER(sampler_CausticTex);
            TEXTURE2D (_RampTex);SAMPLER(sampler_RampTex);
            TEXTURE2D (_CameraDepthTexture);SAMPLER(sampler_CameraDepthTexture);
            TEXTURE2D (_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);
 
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
 
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionVS = TransformWorldToView(o.positionWS);
                o.positionCS = TransformWViewToHClip(o.positionVS);
                float speed = _Time.y * _Speed;
                o.uv.xy = o.positionWS.xz * _FoamTex_ST.xy + speed;
                o.uv.zw = v.uv;
                o.normalUV.xy = TRANSFORM_TEX(v.uv, _NormalTex) + speed * float2(-1.07, 1.07);
                o.normalUV.zw = TRANSFORM_TEX(v.uv, _NormalTex) + speed;
                o.fogCoord = ComputeFogFactor(o.positionCS.z);
 
                return o;
            }
 
            half4 frag(Varyings i) : SV_Target
            {
                half4 c = 0;
                //ˮ�µ�Ť��+��ȹ�����ɫ
                //ʹ����������ķ�����ͼ���������������Ч��
                //������ɫ����֮������1.07������Ϊ�˷�ֹ�ص�ʱͻȻ��һ֡����
                float3 normalUV01 = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.normalUV.xy).xyz;
                float3 normalUV02 = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.normalUV.zw).xyz;
                float3 normalUV = normalUV01 * normalUV02;

                //��Ļ���� = ��Ƭ����Ļ����(0~1) / ��Ļ����(1920*1080)
                float2 screenUV = i.positionCS.xy / _ScreenParams.xy;
                //ƫ�������������Ļ����֮����΢ƫһ��
                float2 distortUV = screenUV + normalUV01.xy * _Distort;

                half depthTex = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV).x;
                half depth = LinearEyeDepth(depthTex, _ZBufferParams);
                half depthWater = depth + i.positionVS.z;

                depthTex = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, distortUV).x;
                depth = LinearEyeDepth(depthTex, _ZBufferParams);
                half depthDistortWater = depth + i.positionVS.z;
                //depth:���ͼ�ϸõ㵽������ü���ľ��롣����0
                //i.positionVS.z:VS�ռ��µ���ȡ�С��0
                //depthWater:δŤ��״̬�µ���ȡ�         |depth|��һ�㣬��λ�ø����ˮ��֮�¡���ֵ>0
                //depthDistortWater:Ť��״̬�µ���ȡ�    |Ƭ�����|��һ�㣬˵�������ؿ�������Ƭ�Ρ���ֵ<0
                float2 opaqueUV;
                //true��ʾ���ͼ��������depth���ϸ�Ƭ�εĸ߶�С��0����û����ˮ��֮��
                //��depthWater�õ�
                if(depthWater < 0)
                {
                    opaqueUV = screenUV;
                }
                else
                {
                    opaqueUV = distortUV;
                    depthWater = depthDistortWater;
                }
                //����Ť�����UV����ץ������ˮ�ϵ�ʹ��δŤ����screenUV��ˮ�µ�ʹ��Ť�����distortUV
                half4 opaqueTex = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, opaqueUV);
                //������Ȳ�����������ˮ�ϵ�ʹ��δŤ����depthWater��ˮ�µ�ʹ��Ť�����depthDistortWater
                half4 waterColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, half2(depthWater * _Depth, 0));

                //----------------��ĭ----------------
                //������ȸ�����ͼһ����Χ����ͼ��ɫ����ڷ�Χ�ڣ��ͷ��ذ�ɫ��������_FoamColor
                half foamTex = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, i.uv.xy).x;
                foamTex = pow(abs(foamTex), _FoamSize);
                half foamRange = depthWater * _FoamRange;
                half foam = step(foamRange, foamTex);
                half4 foamColor = _FoamColor * foam;

                //----------------�߹�----------------
                //Specular = SpecularColor * Ks * pow(NdotH, Smoothness)
                half3 N = lerp(half3(0,1,0), normalUV, 0.8);
                //H = L + V
                half3 V = normalize(_WorldSpaceCameraPos.xyz - i.positionWS);
                half3 H = normalize(GetMainLight().direction + V);
                half NdotH = saturate(dot(N, H));
                half4 specular = _SpecularColor * _Specular * pow(NdotH, _Smoothness);

                //----------------����----------------
                //���Ǹ��ݷ��䣬����ǻ�ȡ��ɫ
                half3 reflectUV = reflect(-V, N);
                half4 reflectTex = SAMPLE_TEXTURECUBE(_ReflectionCube, sampler_ReflectionCube, reflectUV);
                half fresnel = 1 - saturate(dot(half3(0,1,0), V));
                half4 reflect = reflectTex * pow(fresnel, _ReflectionPow);

                //----------------��ɢ----------------
                //ԭ��������������
                float4 depthVS = 1;
                depthVS.xy = i.positionVS.xy * depth / -i.positionVS.z;
                depthVS.z = depth;
                float3 depthWS = mul(unity_CameraToWorld, depthVS).xyz;
                //��ˮ�淨�����ƣ���ˮ����tex01 * tex02��������Ϊ���ý�ɢ��������ʹ����min(tex01, tex02)
                float2 causticUV01 = depthWS.xz * _CausticTex_ST.xy + depthWS.y * 0.05 + _Time.y * _Speed;
                float2 causticUV02 = depthWS.xz * _CausticTex_ST.xy + depthWS.y * 0.08 + _Time.y * _Speed * float2(-1.07, 1.07);
                half4 causticTex01 = SAMPLE_TEXTURE2D(_CausticTex, sampler_CausticTex, causticUV01);
                half4 causticTex02 = SAMPLE_TEXTURE2D(_CausticTex, sampler_CausticTex, causticUV02);
                half4 caustic = min(causticTex01, causticTex02) * _CausticInstensity;

                c += waterColor * _Lightness;
                c += specular * reflect;
                c += foamColor;

                c *= opaqueTex + caustic * _Lightness;
                //Fog
                c.rgb = MixFog(c.rgb, i.fogCoord);
                c.a = 0.5;

                return c;
            }
            ENDHLSL
        }
    }
}