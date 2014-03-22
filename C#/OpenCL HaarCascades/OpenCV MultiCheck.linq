<Query Kind="Program">
  <NuGetReference>OpenCV.Net</NuGetReference>
  <Namespace>System.Drawing</Namespace>
  <Namespace>System.Drawing.Imaging</Namespace>
  <Namespace>System.Runtime.InteropServices</Namespace>
</Query>

void Main()
{
	/*
	 * To check nose, eyes, etc. inside of face area.
	 */
	var queryPath = Path.GetDirectoryName(LINQPad.Util.CurrentQueryPath);
	var cvPath = Path.Combine(@"..\..\..\..");
	var workFile = Path.Combine(cvPath, @"sample\tmp.file");
	
	var cascadeFace = Path.Combine(cvPath, @"sources\data\haarcascades\haarcascade_frontalface_default.xml");
	var cascadeNose = Path.Combine(cvPath, @"sources\data\haarcascades\haarcascade_mcs_nose.xml");
	var cascadeEye = Path.Combine(cvPath, @"sources\data\haarcascades\haarcascade_eye.xml");
	var cascadeMouth = Path.Combine(cvPath, @"sources\data\haarcascades\haarcascade_smile.xml");
	
	var sampleFiles = Path.Combine(cvPath, @"sample\webcam");
	var outPath = Path.Combine(cvPath, @"sample\out\webcam");
	if(sampleFiles == outPath)
		throw new Exception();
	
	var files = Directory.GetFiles(sampleFiles, "*.jpg", SearchOption.AllDirectories);

	foreach(var file in files)
	{
		using(var cvMemStorage = new OpenCV.Net.MemStorage())
		using(var cvHaarClassifierCascadeFace = OpenCV.Net.HaarClassifierCascade.Load(cascadeFace))
		using(var cvImage = OpenCV.Net.CV.LoadImage(file, OpenCV.Net.LoadImageFlags.Color))
		using(var cvSeq = cvHaarClassifierCascadeFace.DetectObjects(
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
				
				var faceImage = cvImage.GetSubRect(cvRect);
				var faceEye = cvImage.GetSubRect(cvRect);
				
				Multiscan(cascadeNose, faceImage, OpenCV.Net.Scalar.Rgb(0, 255, 0));
				Multiscan(cascadeEye, faceImage, OpenCV.Net.Scalar.Rgb(0, 0, 255));
				Multiscan(cascadeMouth, faceImage, OpenCV.Net.Scalar.Rgb(0, 255, 255));
				
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

public int Multiscan(string cascade, OpenCV.Net.IplImage image, OpenCV.Net.Scalar color)
{
	int count = 0;
	
	using(var cvMemStorage = new OpenCV.Net.MemStorage())
	using(var cvHaarClassifierCascade = OpenCV.Net.HaarClassifierCascade.Load(cascade))
	using(var cvSeq = cvHaarClassifierCascade.DetectObjects(image, cvMemStorage, 1.2, 3, OpenCV.Net.HaarDetectObjectFlags.None))
	{
		count = cvSeq.Count;
		for(int i = 0; i < count; i++)
		{
			var cvRect = (OpenCV.Net.Rect)Marshal.PtrToStructure(cvSeq.GetElement(i), typeof(OpenCV.Net.Rect));
			OpenCV.Net.CV.Rectangle(image, cvRect, color, 2, OpenCV.Net.LineFlags.Connected8, 0);
		}
	}
	
	return count;
}