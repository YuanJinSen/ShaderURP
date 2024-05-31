Shader "MyURP/DepthDecal"
{
    Properties
    {
        _BaseColor("Base Color",color) = (1,1,1,1)
        _BaseMap("BaseMap", 2D) = "white" {}
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
        Blend One One
 
        Pass
        {
            Name "DepthDecal"

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
            };
 
            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float fogCoord          : TEXCOORD1;
                float3 positionVS       : TEXCOORD2;
            };
 
            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;
            CBUFFER_END
            TEXTURE2D (_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D (_CameraDepthTexture);SAMPLER(sampler_CameraDepthTexture);
            #define smp _linear_clamp
            SAMPLER(smp);
 
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionVS = TransformWorldToView(positionWS);
                o.positionCS = TransformWViewToHClip(o.positionVS);
                o.fogCoord = ComputeFogFactor(o.positionCS.z);
 
                return o;
            }
 
            half4 frag(Varyings i) : SV_Target
            {
                half4 c;

                float2 screenUV = i.positionCS.xy / _ScreenParams.xy;
                half depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
                //通过深度图求出像素所在的观察空间的Z值
                half depthZ = LinearEyeDepth(depthMap, _ZBufferParams);
                half4 depthVS = half4(0, 0, depthZ, 1);
                //通过当前渲染的面片求出像素在观察空间的XY坐标,使用的是相似三角形的比值,我们有了Z值
                //depthXY:depthZ = vsXY:vsZ
                depthVS.xy = i.positionVS.xy * depthZ / -i.positionVS.z;
                //将此观察空间坐标转换到本地空间，把XY当做UV进行采样
                half4 depthWS = mul(unity_CameraToWorld, depthVS);
                half3 depthOS = mul(unity_WorldToObject, depthWS);
                //采样
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, smp, depthOS.xy + 0.5);
                c = baseMap * _BaseColor;
                //雾效根据混合模式进行了调整
                c.rgb *= saturate(lerp(1, 0, i.fogCoord));

                return c;
            }
            ENDHLSL
        }
    }
}