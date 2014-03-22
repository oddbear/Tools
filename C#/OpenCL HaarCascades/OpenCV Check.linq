<Query Kind="Statements">
  <NuGetReference>OpenCV.Net</NuGetReference>
  <Namespace>System.Drawing</Namespace>
  <Namespace>System.Drawing.Imaging</Namespace>
  <Namespace>System.Runtime.InteropServices</Namespace>
</Query>

/*
 * Tries to find faces using OpenCV - Haar Cascades.
 */
var queryPath = Path.GetDirectoryName(LINQPad.Util.CurrentQueryPath);
var cvPath = Path.Combine(@"..\..\..\..");
var workFile = Path.Combine(cvPath, @"sample\tmp.file");

var cascade = Path.Combine(cvPath, @"sources\data\haarcascades\haarcascade_frontalface_default.xml");
	 //haarcascade_frontalface_default
	 //haarcascade_frontalface_alt
	 //haarcascade_frontalface_alt2
	 //haarcascade_frontalface_alt_tree
	 
var sampleFiles = Path.Combine(cvPath, @"sample\webcam");
var outPath = Path.Combine(cvPath, @"sample\out\webcam");
if(sampleFiles == outPath)
	throw new Exception();

var files = Directory.GetFiles(sampleFiles, "*.jpg", SearchOption.AllDirectories);

using(var cvMemStorage = new OpenCV.Net.MemStorage())
using(var cvHaarClassifierCascade = OpenCV.Net.HaarClassifierCascade.Load(cascade))
{
	foreach(var file in files) //castastudentpanel crowd-reggiewatts-people1000 img_5114
	{
		using(var cvImage = OpenCV.Net.CV.LoadImage(file, OpenCV.Net.LoadImageFlags.Color))
		using(var cvSeq = cvHaarClassifierCascade.DetectObjects(
			cvImage,											//image
			cvMemStorage,										//storage
			1.1,												//scaleFactor
			3,													//minNeighbors
			OpenCV.Net.HaarDetectObjectFlags.None,				//flags
			new OpenCV.Net.Size(20, 20),						//minSize of window, default = 24x24
			new OpenCV.Net.Size(cvImage.Width, cvImage.Height))	//maxSize of window
		) {
			for(int i = 0; i < cvSeq.Count; i++)
			{
				var elem = cvSeq.GetElement(i);
				var cvRect = (OpenCV.Net.Rect)Marshal.PtrToStructure(elem, typeof(OpenCV.Net.Rect));
				
				OpenCV.Net.CV.Rectangle(
					cvImage,							//image to paint on
					cvRect,								//rectangle around face
					OpenCV.Net.Scalar.Rgb(255, 0, 0),	//color
					2,									//thickness
					OpenCV.Net.LineFlags.Connected8,	//lineType
					0									//shift
				);
			}
			
			var outFile = Path.Combine(outPath, file.Substring(sampleFiles.Length + 1));
			Directory.CreateDirectory(Path.GetDirectoryName(outFile));
			OpenCV.Net.CV.SaveImage(outFile, cvImage, null);
			
			var image = System.Drawing.Image.FromFile(outFile);
			//image = (new Bitmap(image, 500, (int)(500m * image.Height / image.Width)));
			image.Dump();
			Path.GetFileNameWithoutExtension(outFile).Dump();
		}
	}
}