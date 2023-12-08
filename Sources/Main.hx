package;

import kha.arrays.Uint32Array;
import kha.arrays.Float32Array;
import kha.graphics4.Usage;
import kha.graphics4.BlendingFactor;
import kha.graphics4.CompareMode;
import kha.Shaders;
import kha.graphics4.VertexData;
import kha.graphics4.PipelineState;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexStructure;
import kha.graphics4.IndexBuffer;
import kha.math.FastMatrix4;
import kha.Assets;
import kha.Color;
import kha.Framebuffer;
import kha.Scheduler;
import kha.System;

class Tex2PipelineState extends PipelineState {

    public function new(doCompile = true, blendMode = "alpha") {
        super();

        var structure:VertexStructure = new VertexStructure();
        structure.add("pos", VertexData.Float2);
        structure.add("uv", VertexData.Float2);

        inputLayout = [structure];

        fragmentShader = Shaders.tex2_frag;
        vertexShader = Shaders.tex2_vert;

        depthWrite = false;
        depthMode = CompareMode.Always;

        if (blendMode == "alpha") {
            useBlendAlpha();
        } else if (blendMode == "multiply") {
            useBlendMultiply();
        }

        if (doCompile) {
            compile();
        }
    }

    public function useBlendMultiply() {
        blendSource = BlendingFactor.DestinationColor;
        blendDestination = BlendingFactor.BlendZero;
        alphaBlendSource = BlendingFactor.BlendZero;
        alphaBlendDestination = BlendingFactor.BlendOne;
    }

    public function useBlendAlpha() {
        blendSource = BlendingFactor.SourceAlpha;
        blendDestination = BlendingFactor.InverseSourceAlpha;
        alphaBlendSource = BlendingFactor.BlendZero;
        alphaBlendDestination = BlendingFactor.BlendOne;
    }
}

class Main {
	static final WIDTH = 1024;
	static final HEIGHT = 768;

	static var matrix2:FastMatrix4;

	static var indexBuffer:IndexBuffer;
    static var vertexBuffer:VertexBuffer;

    static var pipelineState:Tex2PipelineState;

	static function update():Void {}

	static function render(frames:Array<Framebuffer>):Void {
		// As we are using only 1 window, grab the first framebuffer
		final fb = frames[0];

        fb.g4.begin();
        fb.g4.clear(Color.fromFloats(0, 0, 0, 0), 0, 0);
        fb.g4.end();

        fb.g4.begin();
        fb.g4.setPipeline(pipelineState);
        fb.g4.setMatrix(pipelineState.getConstantLocation("mproj"), matrix2);
        fb.g4.setTexture(pipelineState.getTextureUnit("tex"), Assets.images.smiley);
        
        var vertices:Float32Array = vertexBuffer.lock();
        var indices:Uint32Array = indexBuffer.lock();

        var vCounter:Int = 0;
        var numIndices:Int = 0;
        var iCounter:Int = 0;

        function pushV4(x:Float, y:Float, z:Float, w:Float) {
            vertices.set(vCounter, x);
            vertices.set(vCounter + 1, y);
            vertices.set(vCounter + 2, z);
            vertices.set(vCounter + 3, w);
            vCounter += 4;
        }

        function indexQuad() {
            indices[numIndices] = iCounter;
            indices[numIndices + 1] = iCounter + 1;
            indices[numIndices + 2] = iCounter + 3;
            indices[numIndices + 3] = iCounter + 0;
            indices[numIndices + 4] = iCounter + 3;
            indices[numIndices + 5] = iCounter + 2;
            numIndices += 6;
            iCounter += 4;
        }

        function indexTriangle() {
            indices[numIndices] = iCounter;
            indices[numIndices + 1] = iCounter + 1;
            indices[numIndices + 2] = iCounter + 2;
            numIndices += 3;
            iCounter += 3;
        }

        pushV4(0, 0, 0, 0);
        pushV4(0, 100, 0, 1);
        pushV4(100, 0, 1, 0);
        pushV4(100, 100, 1, 1);
        indexQuad();

        pushV4(100, 0, 0, 0);
        pushV4(100, 100, 0, 1);
        pushV4(200, 0, 1, 0);
        pushV4(200, 100, 1, 1);
        indexQuad();

        var numVertices:Int = Std.int(vCounter / 4); // 4 int32 per vertex
        
        indexBuffer.unlock(numIndices);
        vertexBuffer.unlock(numVertices);

        fb.g4.setVertexBuffer(vertexBuffer);
        fb.g4.setIndexBuffer(indexBuffer);
        fb.g4.drawIndexedVertices(0, numIndices);

        fb.g4.end();

        // part 2
        fb.g4.begin();
        fb.g4.setPipeline(pipelineState);
        fb.g4.setMatrix(pipelineState.getConstantLocation("mproj"), matrix2);
        fb.g4.setTexture(pipelineState.getTextureUnit("tex"), Assets.images.frown);
        
        var vertices:Float32Array = vertexBuffer.lock();
        var indices:Uint32Array = indexBuffer.lock();

        vCounter = 0;
        numIndices = 0;
        iCounter = 0;

        pushV4(300 + 0, 0, 0, 0);
        pushV4(300 + 0, 100, 0, 1);
        pushV4(300 + 100, 0, 1, 0);
        indexTriangle();
        
        pushV4(300 + 100, 0, 0, 0);
        pushV4(300 + 100, 100, 0, 1);
        pushV4(300 + 200, 0, 1, 0);
        indexTriangle();

        numVertices = Std.int(vCounter / 4); // 4 int32 per vertex
        indexBuffer.unlock(numIndices);
        vertexBuffer.unlock(numVertices);

        fb.g4.setVertexBuffer(vertexBuffer);
        fb.g4.setIndexBuffer(indexBuffer);
        fb.g4.drawIndexedVertices(0, numIndices);
        fb.g4.end();
	}

	public static function main() {
		System.start({title: "Project", width: WIDTH, height: HEIGHT}, function(_) {
			// Just loading everything is ok for small projects
			Assets.loadEverything(function() {
				// Avoid passing update/render directly,
				// so replacing them via code injection works

                // MVP
                matrix2 = FastMatrix4.identity();
                matrix2 = (FastMatrix4.translation(-WIDTH / 2, -HEIGHT / 2, 0).multmat(matrix2));
                matrix2 = (FastMatrix4.scale(2 / WIDTH, -2 / HEIGHT, -1).multmat(matrix2));
                matrix2 = (FastMatrix4.translation(2 / WIDTH, 2 / HEIGHT, 1).multmat(matrix2));

                // pipeline
                pipelineState = new Tex2PipelineState();
                
                // initialize vertex buffer
                vertexBuffer = new VertexBuffer(8192, pipelineState.inputLayout[0], Usage.DynamicUsage);
                indexBuffer = new IndexBuffer(12288, Usage.DynamicUsage);

				Scheduler.addTimeTask(function() {
					update();
				}, 0, 1 / 60);
				System.notifyOnFrames(function(frames) {
					render(frames);
				});
			});
		});
	}
}
